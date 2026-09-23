//
//  AppLockSettingsView.swift
//  Diary
//
//  설정 > 보안 > 앱 잠금 화면.
//  잠금 켜기/끄기와 PIN 변경을 담당한다. (생체인증 토글은 Phase 4에서 여기 추가된다)
//
//  [진실의 원천]
//  "잠금이 켜져 있는가" = "Keychain에 PIN 자격증명이 있는가" 이다.
//  화면에 보이는 토글은 그 상태를 비추는 거울일 뿐이라, 화면에 들어올 때마다 Keychain에서 다시 읽는다.
//  UserDefaults에 켜짐 여부를 따로 들고 있으면 두 값이 어긋나는 순간
//  "토글은 켜져 있는데 PIN은 없는" 상태가 만들어져 잠금이 통째로 새어나간다.
//

import SwiftUI

struct AppLockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lockManager: AppLockManager

    /// 화면에 표시되는 잠금 상태. Keychain에서 읽어 채운다.
    @State private var isLockEnabled: Bool = false
    /// Keychain을 읽지 못한 상태. 이때는 토글을 만지지 못하게 막는다.
    @State private var isUnavailable: Bool = false

    /// 표시 중인 전체 화면 플로우.
    private enum Flow: Identifiable {
        case setup          // 최초 설정
        case change         // PIN 변경 (현재 PIN 확인 → 새 PIN)
        case disable        // 잠금 끄기 (현재 PIN 확인)

        var id: Int { hashValue }
    }
    @State private var flow: Flow?
    /// 변경 플로우에서 현재 PIN 확인을 통과했는지.
    @State private var didVerifyForChange: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    lockToggleCard

                    if isLockEnabled {
                        changePinCard
                    }

                    Text(guideText)
                        .customFont(size: 13)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xs)
                }
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("앱 잠금")
                        .customFont(size: 20)
                        .foregroundStyle(AppColor.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .tint(.clear)
                }
            }
            .onAppear(perform: refreshState)
            .fullScreenCover(item: $flow, content: flowView)
        }
    }

    // MARK: - 카드

    private var lockToggleCard: some View {
        HStack(spacing: AppSpacing.md) {
            iconBadge(systemName: "lock.fill", color: AppColor.calendarPastels[4])

            Text("앱 잠금")
                .customFont(size: 16)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            // 토글을 직접 바인딩하지 않는 이유:
            // 켜기는 PIN 설정을, 끄기는 PIN 확인을 통과해야 비로소 상태가 바뀐다.
            // 바인딩으로 두면 사용자가 손댄 순간 토글이 먼저 움직여, 실제 상태와 어긋나 보인다.
            Toggle("", isOn: Binding(get: { isLockEnabled },
                                     set: { handleToggle(to: $0) }))
                .labelsHidden()
                .tint(AppColor.accent)
                .disabled(isUnavailable)
        }
        .padding(AppSpacing.md)
        .background(cardBackground)
    }

    private var changePinCard: some View {
        Button {
            didVerifyForChange = false
            flow = .change
        } label: {
            HStack(spacing: AppSpacing.md) {
                iconBadge(systemName: "key.fill", color: AppColor.calendarPastels[2])

                Text("PIN 변경")
                    .customFont(size: 16)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary.opacity(0.6))
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .background(cardBackground)
    }

    private var guideText: LocalizedStringKey {
        if isUnavailable {
            return "지금은 잠금 설정을 변경할 수 없어요. 잠시 후 다시 시도해 주세요."
        }
        // 복구 불가 경고는 설정 화면에서도 계속 보이게 둔다.
        // 백업 기능이 나오면 이 문구를 "백업으로 복구할 수 있어요"로 교체한다.
        return "앱을 열 때 PIN을 입력해야 일기를 볼 수 있어요. PIN을 잊으면 복구할 수 없으니 잊지 않도록 주의해 주세요."
    }

    // MARK: - 동작

    private func refreshState() {
        do {
            isLockEnabled = try AppLockStore.isPinSet()
            isUnavailable = false
        } catch {
            // 읽기에 실패하면 '꺼짐'으로 단정하지 않는다.
            // 꺼짐으로 보이면 사용자가 토글을 켜면서 기존 PIN을 덮어쓸 수 있다.
            isUnavailable = true
        }
    }

    private func handleToggle(to newValue: Bool) {
        guard !isUnavailable else { return }
        flow = newValue ? .setup : .disable
    }

    @ViewBuilder
    private func flowView(for flow: Flow) -> some View {
        switch flow {
        case .setup:
            PinSetupView(onFinished: finishFlow, onCancel: finishFlow)

        case .disable:
            verifyFlow(title: "잠금을 끄려면 PIN을 입력해 주세요") {
                try? AppLockStore.clear()
                finishFlow()
            }

        case .change:
            // 변경은 2단계다. 현재 PIN 확인을 통과하면 같은 시트 안에서 새 PIN 입력으로 넘어간다.
            if didVerifyForChange {
                PinSetupView(onFinished: finishFlow, onCancel: finishFlow)
            } else {
                verifyFlow(title: "현재 PIN을 입력해 주세요") {
                    didVerifyForChange = true
                }
            }
        }
    }

    /// PinVerifyView 자체에는 빠져나갈 수단이 없다(잠금 화면에서 그러면 안 되므로).
    /// 설정에서 띄울 때만 취소 버튼을 여기서 씌워 준다.
    private func verifyFlow(title: LocalizedStringKey,
                            onVerified: @escaping () -> Void) -> some View {
        NavigationStack {
            PinVerifyView(title: title, onVerified: onVerified)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("취소") { finishFlow() }
                            .customFont(size: 16)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
        }
    }

    /// 어떤 플로우든 끝나면 시트를 닫고 상태를 Keychain 기준으로 다시 맞춘다.
    private func finishFlow() {
        flow = nil
        didVerifyForChange = false
        refreshState()
        // 잠금을 껐다면 상태머신도 같이 풀어 준다.
        // (안 그러면 잠금은 꺼졌는데 다음 복귀 때 잠금 화면이 뜨는 상태로 남는다)
        lockManager.revalidate()
    }

    // MARK: - 공통 조각

    private func iconBadge(systemName: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(color)
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: systemName)
                    .resizable().scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(AppColor.textPrimary)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            .fill(AppColor.surface)
            .shadow(color: AppShadow.color, radius: AppShadow.radius,
                    x: AppShadow.x, y: AppShadow.y)
    }
}

#Preview {
    AppLockSettingsView()
        .environmentObject(FontManager())
        .environmentObject(AppLockManager())
}
