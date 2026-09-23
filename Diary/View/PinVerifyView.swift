//
//  PinVerifyView.swift
//  Diary
//
//  기존 PIN을 확인하는 화면. PIN 변경 / 잠금 해제 전에 본인 확인 용도로 쓴다.
//  Phase 3의 잠금 해제 화면도 이 화면을 기반으로 확장한다.
//
//  [실패 지연 처리]
//  AppLockStore.verify()는 지연 중인지 스스로 확인하지 않는다. 남은 시간을 초 단위로
//  보여줘야 하는 건 화면의 책임이기 때문이다. 그래서 여기서
//    1) 화면 진입 시와 매 초 남은 시간을 조회하고
//    2) 남아 있으면 키패드를 막고 카운트다운을 보여주고
//    3) 0이 된 순간 입력을 다시 연다.
//

import SwiftUI

struct PinVerifyView: View {
    /// 화면 상단 제목. 호출 목적(변경/해제)에 따라 부모가 정한다.
    var title: LocalizedStringKey = "현재 PIN을 입력해 주세요"
    /// 검증 성공.
    var onVerified: () -> Void

    @State private var pin: String = ""
    @State private var error: PinInputMessage?
    @State private var lockoutNote: String?
    @State private var remainingLockout: TimeInterval = 0
    @State private var readFailed: Bool = false

    /// 카운트다운용 1초 타이머. 지연이 없을 때도 돌지만 비용이 없고,
    /// 다른 화면에서 실패가 누적된 경우에도 상태가 곧 반영된다는 장점이 있다.
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // NavigationStack과 취소 버튼을 이 안에 두지 않는다.
    // 잠금 해제 화면에서는 빠져나갈 수단이 있으면 안 되고(취소로 잠금을 우회하게 된다),
    // 설정에서 띄울 때만 부모가 NavigationStack + 취소 버튼을 감싸면 된다.
    var body: some View {
        PinInputView(title: title,
                     message: nil,
                     pin: $pin,
                     error: error,
                     note: lockoutNote,
                     isDisabled: remainingLockout > 0,
                     onComplete: handleComplete)
            .onAppear { refreshLockout() }
            .onReceive(ticker) { _ in refreshLockout() }
            .alert("확인할 수 없어요", isPresented: $readFailed) {
                // 여기서 화면을 닫지 않는다. 잠금 화면이라면 닫는 순간 잠금이 뚫린다.
                // 입력만 비우고 다시 시도하게 둔다.
                Button("확인", role: .cancel) { pin = "" }
            } message: {
                Text("잠시 후 다시 시도해 주세요.")
            }
    }

    // MARK: - 검증

    private func handleComplete(_ value: String) {
        // 입력이 진행되는 사이에 지연이 시작됐을 수도 있으므로 한 번 더 확인한다.
        refreshLockout()
        guard remainingLockout <= 0 else {
            pin = ""
            return
        }

        do {
            if try AppLockStore.verify(value) {
                onVerified()
            } else {
                pin = ""
                // 틀렸다는 사실은 흔들림으로 한 번만 알린다.
                error = PinInputMessage(String(localized: "PIN이 맞지 않아요"))
                // verify() 안에서 실패가 기록되며 지연이 시작될 수 있으니 즉시 다시 읽는다.
                // 지연이 걸렸다면 카운트다운(note)이 위 문구를 덮어쓴다.
                refreshLockout()
            }
        } catch {
            // Keychain 읽기 실패 등. 조용히 통과시키지 않고 화면을 닫는다.
            readFailed = true
        }
    }

    // MARK: - 지연 상태

    private func refreshLockout() {
        // 지연 상태를 못 읽으면 '지연 없음'이 아니라 보수적으로 직전 값을 유지한다.
        remainingLockout = (try? AppLockStore.remainingLockoutSeconds()) ?? remainingLockout

        if remainingLockout > 0 {
            let seconds = Int(ceil(remainingLockout))
            lockoutNote = String(format: String(localized: "너무 여러 번 틀렸어요. %d초 후에 다시 시도해 주세요."),
                                 seconds)
        } else if lockoutNote != nil {
            // 지연이 막 끝났다. 문구를 모두 지워 입력이 다시 열렸음을 알린다.
            lockoutNote = nil
            error = nil
        }
    }
}

#Preview {
    PinVerifyView(onVerified: {})
        .environmentObject(FontManager())
}
