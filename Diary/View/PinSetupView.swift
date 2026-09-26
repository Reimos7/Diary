//
//  PinSetupView.swift
//  Diary
//
//  PIN 최초 설정 / 변경 화면. 두 단계로 입력받는다.
//    1) 새 PIN 입력  2) 같은 PIN 재입력으로 확인
//
//  [왜 재입력을 받는가]
//  오타로 설정된 PIN은 사용자가 영영 알 수 없고, 굿디는 PIN 분실 시 복구 수단이 제한적이라
//  (생체 미등록 상태면 사실상 복구 불가) 설정 단계에서 막는 것이 유일한 방어선이다.
//

import SwiftUI

struct PinSetupView: View {
    /// 설정이 끝나면 호출. 부모가 화면을 닫는다.
    var onFinished: () -> Void
    /// 사용자가 중간에 취소.
    var onCancel: () -> Void

    private enum Step {
        case create   // 새 PIN 입력
        case confirm  // 재입력 확인
    }

    @State private var step: Step = .create
    @State private var firstPin: String = ""
    @State private var pin: String = ""
    @State private var error: PinInputMessage?
    @State private var saveFailed: Bool = false

    var body: some View {
        NavigationStack {
            PinInputView(title: title,
                         message: message,
                         pin: $pin,
                         error: error,
                         onComplete: handleComplete)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") { onCancel() }
                            .customFont(size: 16)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .alert("PIN을 저장하지 못했어요", isPresented: $saveFailed) {
                    Button("확인", role: .cancel) { reset(to: .create) }
                } message: {
                    Text("잠시 후 다시 시도해 주세요.")
                }
        }
    }

    // MARK: - 문구

    private var title: LocalizedStringKey {
        switch step {
        case .create: return "새 PIN을 입력해 주세요"
        case .confirm: return "한 번 더 입력해 주세요"
        }
    }

    private var message: LocalizedStringKey? {
        switch step {
        case .create:
            // 복구 불가 경고는 설정 시점에 반드시 보여준다.
            // 백업 기능이 나오면 이 문구를 "백업으로 복구할 수 있어요"로 교체한다.
            return "PIN을 잊으면 일기를 다시 볼 수 없어요. 신중하게 정해 주세요."
        case .confirm:
            return nil
        }
    }

    // MARK: - 단계 처리

    private func handleComplete(_ value: String) {
        switch step {
        case .create:
            firstPin = value
            reset(to: .confirm)

        case .confirm:
            guard value == firstPin else {
                // 불일치하면 처음부터 다시 받는다.
                // 확인 단계만 되돌리면, 첫 입력이 오타였을 때 사용자가 같은 오타를 반복하게 된다.
                firstPin = ""
                reset(to: .create,
                      message: PinInputMessage(String(localized: "PIN이 일치하지 않아요. 처음부터 다시 입력해 주세요.")))
                return
            }

            do {
                try AppLockStore.setPin(value)
                onFinished()
            } catch {
                saveFailed = true
            }
        }
    }

    private func reset(to newStep: Step, message: PinInputMessage? = nil) {
        pin = ""
        error = message
        step = newStep
    }
}

#Preview {
    PinSetupView(onFinished: {}, onCancel: {})
        .environmentObject(FontManager())
}
