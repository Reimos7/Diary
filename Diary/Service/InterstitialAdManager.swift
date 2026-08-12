//
//  InterstitialAdManager.swift
//  Diary
//
//  전면(전체화면) 광고 매니저.
//
//  [정책/UX 원칙]
//  - 일기를 "저장 완료"한 직후(작성 화면이 닫힌 자연스러운 정지점)에만 노출한다. 작성 도중엔 절대 X.
//  - saveInterval 회 저장마다 1번만 노출하고(빈도 제한), 저장 횟수는 앱을 껐다 켜도 누적된다(UserDefaults).
//    → 하루 한 번 쓰는 저사용 유저도 며칠에 한 번은 자연스럽게 노출된다.
//  - 최소 노출 간격(minInterval)으로 짧은 시간 내 중복 노출을 막는다.
//  - 광고는 미리 로드(preload)해 두고, 닫히면 즉시 다음 것을 로드한다.
//

import UIKit
import GoogleMobileAds

final class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitial: InterstitialAd?

    /// 저장 몇 회마다 노출할지
    private let saveInterval = 3
    /// 최소 노출 간격(초). 이 시간 안에는 다시 안 띄운다.
    private let minInterval: TimeInterval = 120
    /// 마지막 노출 시각(세션 내 중복 방지용)
    private var lastShownAt: Date?

    /// 누적 저장 횟수(앱 재실행에도 유지)
    private var saveCount: Int {
        get { UserDefaults.standard.integer(forKey: "interstitialSaveCount") }
        set { UserDefaults.standard.set(newValue, forKey: "interstitialSaveCount") }
    }

    private override init() { super.init() }

    /// 미리 로드해 둔다. (앱 시작 시 1회 + 광고가 닫힐 때마다 호출)
    func preload() {
        InterstitialAd.load(with: AdConfig.interstitialUnitID, request: AdConfig.makeRequest()) { [weak self] ad, error in
            if let error = error {
                #if DEBUG
                print("전면 광고 로드 실패: \(error.localizedDescription)")
                #endif
                return
            }
            self?.interstitial = ad
            ad?.fullScreenContentDelegate = self
            #if DEBUG
            print("전면 광고 로드 성공")
            #endif
        }
    }

    /// 일기 저장 시 호출. 조건 충족 시 작성 화면이 닫힌 뒤 전면 광고를 띄운다.
    func notifyDiarySaved() {
        saveCount += 1
        guard saveCount % saveInterval == 0 else { return }
        if let last = lastShownAt, Date().timeIntervalSince(last) < minInterval { return }

        // 작성 화면(fullScreenCover) dismiss가 끝난 뒤 표시되도록 살짝 지연.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.present()
        }
    }

    private func present() {
        guard let interstitial, let top = Self.topViewController() else {
            preload()   // 준비 안 됐으면 다음을 위해 다시 로드
            return
        }
        interstitial.present(from: top)
        lastShownAt = Date()
    }

    /// 현재 최상단 뷰 컨트롤러(모달까지 따라 올라간다).
    private static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    // 광고가 닫히면 다음 광고를 미리 로드한다.
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        preload()
    }
    // 표시 실패 시에도 정리하고 다음을 로드한다.
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        #if DEBUG
        print("전면 광고 표시 실패: \(error.localizedDescription)")
        #endif
        interstitial = nil
        preload()
    }
}
