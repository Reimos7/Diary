//
//  SettingView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//  새 디자인: 그룹 카드 + 파스텔 원형 아이콘 (스티치 스타일).
//  기능(알림/테마/폰트/언어 이동, 문의, 앱평가, 버전 표시)은 기존 그대로.
//

import SwiftUI

struct SettingView: View {
    private var email = EmailManager(toAddress: EmailAddress.developerEmail, subject: "굿디 문의하기")

    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject var manager: SwiftDataManager

    @AppStorage("appLanguage") private var appLanguage: String = resolvedSystemLanguage()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // 그룹 1: 개인화
                    groupCard {
                        NavigationLink { NotificationView() } label: {
                            settingRow(icon: "notification_img", color: AppColor.calendarPastels[0], title: "알림")
                        }
                        rowDivider
                        NavigationLink { ThemeView() } label: {
                            settingRow(icon: "theme_img", color: AppColor.calendarPastels[1], title: "테마")
                        }
                        rowDivider
                        NavigationLink { FontView() } label: {
                            settingRow(icon: "font_img", color: AppColor.calendarPastels[2], title: "폰트")
                        }
                        rowDivider
                        NavigationLink { LanguageView() } label: {
                            settingRow(icon: "globe", color: AppColor.calendarPastels[4], title: "언어",
                                       value: currentLanguageDisplayName(), isSystemIcon: true)
                        }
                    }

                    // 그룹 2: 지원
                    groupCard {
                        Button {
                            email.send(openURL: openURL)
                        } label: {
                            settingRow(icon: "email_img", color: AppColor.calendarPastels[3], title: "문의하기")
                        }
                        rowDivider
                        Button {
                            let urlString = "https://apps.apple.com/app/id\(AppID.diaryAppID)?action=write-review"
                            if let url = URL(string: urlString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            settingRow(icon: "store_img", color: AppColor.calendarPastels[0], title: "앱 평가하기")
                        }
                    }

                    // 그룹 3: 정보
                    groupCard {
                        settingRow(icon: "appVersion_img", color: AppColor.calendarPastels[2], title: "앱 버전",
                                   value: Bundle.main.appVersion, showChevron: false)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("설정")
                        .customFont(size: 20)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAutorization()
        }
        .trackScreen("Setting")
    }

    // MARK: - 그룹 카드

    private func groupCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // 행 사이 구분선 (아이콘 너비만큼 들여쓰기)
    private var rowDivider: some View {
        Rectangle()
            .fill(AppColor.divider)
            .frame(height: 1)
            .padding(.leading, 64)
    }

    // MARK: - 설정 행

    private func settingRow(icon: String, color: Color, title: String,
                            value: String? = nil, showChevron: Bool = true,
                            isSystemIcon: Bool = false) -> some View {
        HStack(spacing: AppSpacing.md) {
            // 파스텔 원형 아이콘 배지
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color)
                .frame(width: 38, height: 38)
                .overlay(
                    Group {
                        if isSystemIcon {
                            Image(systemName: icon).resizable().scaledToFit().frame(width: 20, height: 20)
                        } else {
                            Image(icon).resizable().scaledToFit().frame(width: 22, height: 22)
                        }
                    }
                    .foregroundStyle(AppColor.textPrimary)
                )

            Text(title)
                .customFont(size: 16)
                .foregroundStyle(AppColor.textPrimary)

            Spacer()

            if let value {
                Text(value)
                    .customFont(size: 14)
                    .foregroundStyle(AppColor.textSecondary)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.md)
        .contentShape(Rectangle())
    }

    // 현재 앱에 설정된 언어를 사용자에게 보여줄 이름으로 변환
    private func currentLanguageDisplayName() -> String {
        switch appLanguage {
        case "ko": return "한국어"
        case "en": return "English"
        case "ja": return "日本語"
        default: return appLanguage
        }
    }
}

#Preview {
    SettingView()
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
