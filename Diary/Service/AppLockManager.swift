//
//  AppLockManager.swift
//  Diary
//
//  앱 잠금의 상태머신. "언제 잠그고 언제 푸는가"만 책임진다.
//  PIN 저장·검증은 AppLockStore가, 화면은 LockGateView가 담당한다.
//
//  [왜 Bool 두 개가 아니라 enum인가]
//  isLocked / isAuthenticating 같은 Bool 조합으로 두면
//  "잠겼는데 동시에 해제됨" 같은 불가능한 상태가 표현 가능해지고,
//  생체인증 중 재잠금 같은 버그가 바로 거기서 나온다. 상태는 항상 셋 중 하나다.
//
//  [왜 scenePhase가 아니라 알림(Notification)인가]
//  scenePhase의 .inactive/.background는 "앱을 떠났다"와 "앱 안에서 모달이 떴다"를 구분하지 못한다.
//  굿디는 일기 저장 3회마다 전면광고를 띄우므로, scenePhase로 잠그면
//  광고를 닫고 돌아올 때마다 잠금 화면이 튀어나온다. (생체인증 프롬프트도 같은 문제)
//
//  그래서 두 신호를 목적에 맞게 나눠 쓴다.
//    · didEnterBackground  → 진짜로 앱을 떠남.      잠금 타이머 시작
//    · willResignActive    → 화면이 가려질 수 있음.  앱 스위처 스냅샷 커버
//  앱 내부 모달(광고·사진 선택기)은 둘 다 발생시키지 않으므로 자연히 걸러진다.
//

import Foundation
import UIKit

final class AppLockManager: ObservableObject {

    enum State: Equatable {
        /// 잠금이 꺼져 있거나, 이미 인증을 통과한 상태.
        case unlocked
        /// 잠겨 있음. PIN(또는 생체) 인증이 필요하다.
        case locked
        /// 생체인증 프롬프트 표시 중. (Phase 4에서 사용)
        case authenticating
    }

    /// 앱을 떠났다가 이 시간 안에 돌아오면 잠그지 않는다.
    /// 실수로 나갔다 바로 돌아오는 경우와, 광고 링크로 App Store에 다녀오는 경우를 흡수한다.
    static let graceInterval: TimeInterval = 30

    @Published private(set) var state: State = .unlocked

    /// 앱 스위처 스냅샷 등에서 내용을 가려야 하는지.
    /// 잠금과 별개의 축이다. (잠금이 꺼져 있어도 커버는 필요하지 않지만,
    ///  잠금이 켜져 있고 해제된 상태에서 스위처로 가면 커버가 필요하다)
    @Published private(set) var isCovered: Bool = false

    /// 앱을 떠난 시각. 돌아왔을 때 유예 시간을 계산하는 기준.
    private var backgroundedAt: Date?

    private var observers: [NSObjectProtocol] = []

    init() {
        state = Self.resolveInitialState()
        registerLifecycleObservers()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - 외부 조작

    /// 인증 성공. 잠금을 푼다.
    func unlock() {
        backgroundedAt = nil
        state = .unlocked
    }

    /// 즉시 잠근다. (잠금이 꺼져 있으면 아무 일도 하지 않는다)
    func lock() {
        guard isLockEnabled else { return }
        state = .locked
    }

    /// 생체인증 프롬프트를 띄우기 직전/직후에 호출한다. (Phase 4)
    func setAuthenticating(_ isAuthenticating: Bool) {
        guard state != .unlocked else { return }
        state = isAuthenticating ? .authenticating : .locked
    }

    /// 설정 화면에서 잠금을 켜거나 끈 뒤, 또는 잠금 화면이 떠 있는 동안 주기적으로 호출한다.
    ///
    /// 잠금이 꺼져 있는데 잠긴 상태로 남아 있으면 앱이 영영 안 열리므로,
    /// 실제 저장소 상태와 화면 상태를 다시 맞춘다.
    /// (콜드런치 때 Keychain을 읽지 못해 보수적으로 잠근 경우를 되돌리는 통로이기도 하다)
    func revalidate() {
        if !isLockEnabled {
            unlock()
        }
    }

    // MARK: - 상태 판단

    /// 잠금이 켜져 있는가. 읽기에 실패하면 "켜져 있다"고 본다.
    ///
    /// 실패를 "꺼짐"으로 해석하면 잠금이 통째로 열려버린다.
    /// 반대로 해석하면 최악의 경우 잠금 화면이 한 번 더 뜨는 것에 그치고,
    /// revalidate()로 회복할 수 있다. 보안 기본값은 항상 더 안전한 쪽이어야 한다.
    private var isLockEnabled: Bool {
        (try? AppLockStore.isPinSet()) ?? true
    }

    /// 콜드런치 시 상태. 잠금이 켜져 있으면 무조건 잠긴 채로 시작한다.
    private static func resolveInitialState() -> State {
        do {
            return try AppLockStore.isPinSet() ? .locked : .unlocked
        } catch {
            return .locked
        }
    }

    // MARK: - 생명주기

    private func registerLifecycleObservers() {
        let center = NotificationCenter.default

        // 진짜로 앱을 떠났다. 돌아올 때 유예 시간을 재기 위해 시각을 남긴다.
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                           object: nil, queue: .main) { [weak self] _ in
            self?.handleDidEnterBackground()
        })

        // 돌아왔다. 유예 시간을 넘겼으면 잠근다.
        observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                           object: nil, queue: .main) { [weak self] _ in
            self?.handleWillEnterForeground()
        })

        // 화면이 가려질 수 있다. 앱 스위처 스냅샷에 일기가 남지 않도록 덮는다.
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification,
                                           object: nil, queue: .main) { [weak self] _ in
            self?.isCovered = true
        })

        observers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                           object: nil, queue: .main) { [weak self] _ in
            self?.isCovered = false
        })
    }

    private func handleDidEnterBackground() {
        guard isLockEnabled else { return }

        // 생체인증 도중에 실제로 앱을 떠난 경우. 인증 중 상태로 남겨두면
        // 돌아왔을 때 프롬프트도 잠금 화면도 없는 어정쩡한 화면이 된다.
        if state == .authenticating {
            state = .locked
        }

        backgroundedAt = Date()
    }

    private func handleWillEnterForeground() {
        guard isLockEnabled, let backgroundedAt else { return }
        self.backgroundedAt = nil

        // 시계가 과거로 조작됐다면 경과 시간을 신뢰할 수 없으므로 잠근다.
        let elapsed = Date().timeIntervalSince(backgroundedAt)
        if elapsed < 0 || elapsed >= Self.graceInterval {
            state = .locked
        }
    }
}
