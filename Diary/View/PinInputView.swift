//
//  PinInputView.swift
//  Diary
//
//  PIN 입력 화면의 공통 UI. (점 인디케이터 + 커스텀 숫자 키패드)
//  설정/변경(PinSetupView), 확인(PinVerifyView), 그리고 Phase 3의 잠금 해제 화면이 모두 이걸 쓴다.
//
//  [왜 시스템 키보드를 쓰지 않는가]
//  - 숫자 키패드라도 시스템 키보드는 높이가 기기마다 달라 레이아웃이 흔들리고,
//    붙여넣기/받아쓰기 같은 불필요한 입력 경로가 열린다.
//  - 굿디의 크림·손글씨 톤과 이질적이다.
//  그래서 자리 수 고정 + 숫자만 받는 전용 키패드를 직접 만든다.
//

import SwiftUI
import UIKit

// MARK: - 오류 문구

/// PIN 입력 화면의 오류/안내 문구.
///
/// 문자열이 아니라 이 타입으로 받는 이유: 같은 문구("PIN이 맞지 않아요")가 연달아 발생할 때도
/// 흔들림 애니메이션이 다시 재생되어야 한다. 매번 새 id를 갖게 해 onChange가 반드시 걸리게 한다.
struct PinInputMessage: Equatable {
    let id = UUID()
    let text: String

    init(_ text: String) {
        self.text = text
    }
}

// MARK: - 입력 화면 본체

struct PinInputView: View {
    /// 상단 큰 제목 (예: "새 PIN을 입력해 주세요")
    let title: LocalizedStringKey
    /// 제목 아래 보조 설명. 없으면 생략된다.
    var message: LocalizedStringKey?
    /// 현재 입력값. 부모가 단계 전환 시 "" 로 비운다.
    @Binding var pin: String
    /// 오류 문구. 값이 들어올 때마다 흔들림 + 햅틱이 한 번 재생된다.
    var error: PinInputMessage?
    /// 흔들지 않는 상태 문구(예: 지연 카운트다운). 매 초 바뀌어도 화면이 요동치지 않는다.
    /// 표시 우선순위는 note가 error보다 높다. (지연 중에는 남은 시간이 더 중요한 정보)
    var note: String?
    /// 지연(lockout) 중에는 입력을 통째로 막는다.
    var isDisabled: Bool = false
    /// pin이 정해진 자릿수를 채우면 호출된다.
    var onComplete: (String) -> Void

    @State private var shakeTrigger: CGFloat = 0

    private let length = AppLockStore.pinLength

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer(minLength: AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .customFont(size: 20)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                if let message {
                    Text(message)
                        .customFont(size: 14)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, AppSpacing.lg)

            PinDotsView(filled: pin.count, total: length, isError: error != nil || note != nil)
                .modifier(ShakeEffect(animatableData: shakeTrigger))

            // 문구 자리를 항상 확보해 두어, 문구가 나타날 때 키패드가 밀리지 않게 한다.
            Text(note ?? error?.text ?? " ")
                .customFont(size: 14)
                .foregroundStyle(AppColor.sunday)
                .multilineTextAlignment(.center)
                .frame(minHeight: 20)
                .padding(.horizontal, AppSpacing.lg)

            Spacer(minLength: 0)

            PinKeypad(isDisabled: isDisabled, onDigit: append, onDelete: deleteLast)
                .padding(.bottom, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
        .onChange(of: error) { _, newValue in
            guard newValue != nil else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default) { shakeTrigger += 1 }
        }
    }

    // MARK: 입력 처리

    private func append(_ digit: String) {
        guard !isDisabled, pin.count < length else { return }
        pin += digit

        // 마지막 자리를 채우면 곧바로 제출한다.
        // 애니메이션(점이 채워지는 모습)이 보이도록 아주 짧게 미룬다.
        if pin.count == length {
            let submitted = pin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                onComplete(submitted)
            }
        }
    }

    private func deleteLast() {
        guard !isDisabled, !pin.isEmpty else { return }
        pin.removeLast()
    }
}

// MARK: - 점 인디케이터

struct PinDotsView: View {
    let filled: Int
    let total: Int
    var isError: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .strokeBorder(borderColor, lineWidth: 1.5)
                    .background(Circle().fill(index < filled ? fillColor : .clear))
                    .frame(width: 16, height: 16)
            }
        }
        .animation(.easeOut(duration: 0.15), value: filled)
    }

    private var borderColor: Color {
        isError ? AppColor.sunday : AppColor.divider
    }

    private var fillColor: Color {
        isError ? AppColor.sunday : AppColor.accent
    }
}

// MARK: - 숫자 키패드

private struct PinKeypad: View {
    var isDisabled: Bool
    var onDigit: (String) -> Void
    var onDelete: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["", "0", "delete"]
    ]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: AppSpacing.xl) {
                    ForEach(row, id: \.self) { key in
                        keyButton(for: key)
                    }
                }
            }
        }
        .opacity(isDisabled ? 0.4 : 1)
        .allowsHitTesting(!isDisabled)
    }

    @ViewBuilder
    private func keyButton(for key: String) -> some View {
        switch key {
        case "":
            // 좌하단 빈 자리. 열 간격을 유지하기 위한 투명 placeholder.
            Color.clear.frame(width: 68, height: 68)

        case "delete":
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDelete()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 68, height: 68)
                    .contentShape(Circle())
            }
            .accessibilityLabel(Text("지우기"))

        default:
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDigit(key)
            } label: {
                Text(key)
                    .customFont(size: 28)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(AppColor.surface)
                            .shadow(color: AppShadow.color, radius: AppShadow.radius,
                                    x: AppShadow.x, y: AppShadow.y)
                    )
            }
        }
    }
}

// MARK: - 흔들림 효과

/// 틀렸을 때 좌우로 짧게 흔드는 효과. animatableData를 1씩 올리면 한 번 재생된다.
struct ShakeEffect: GeometryEffect {
    var travel: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = travel * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

#Preview {
    PinInputView(title: "PIN을 입력해 주세요",
                 message: "일기를 열려면 PIN이 필요해요",
                 pin: .constant("12"),
                 error: nil,
                 onComplete: { _ in })
    .environmentObject(FontManager())
}
