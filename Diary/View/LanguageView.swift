//
//  LanguageView.swift
//  Diary
//
//  Created by Reimos on 3/1/26.
//  새 디자인: 종이 배경 + 상단 미리보기 카드 + 언어 선택 그룹 카드.
//  언어 변경/위젯 동기화/Analytics 로직은 기존 그대로.
//

import SwiftUI
import WidgetKit

struct LanguageView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: WeatherService

    @AppStorage("appLanguage") private var appLanguage: String = resolvedSystemLanguage()

    private let languages: [(code: String, name: String, sample: String)] = [
        ("ko", "한국어", "매일 매일이 행복한 하루가 되길 바랄게"),
        ("en", "English", "I hope every day is a happy day for you"),
        ("ja", "日本語", "毎日毎日が幸せな一日になりますように")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    previewCard
                    languageCard
                }
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("언어 설정")
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
        }
    }

    // MARK: - 상단 미리보기 (날씨 + 날짜 + 선택 언어 예시 문장)

    private var previewCard: some View {
        VStack(spacing: AppSpacing.sm) {
            if service.showLocationDeniedWeatherView {
                Text("위치 권한을 허용하면\n날씨를 기록할 수 있어요")
                    .customFont(size: 13)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            } else if let model = service.currentWeather {
                WeatherIconView(symbol: model.icon, size: 70)
            }

            Text(DateFormatter.dateFormatter.string(from: Date.now))
                .customFont(size: 15)
                .foregroundStyle(AppColor.textSecondary)

            Text(languages.first(where: { $0.code == appLanguage })?.sample ?? languages[0].sample)
                .customFont(size: 16)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - 언어 선택 카드

    private var languageCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(languages.enumerated()), id: \.element.code) { index, language in
                Button {
                    selectLanguage(language.code)
                } label: {
                    HStack {
                        Text(language.name)
                            .customFont(size: 16)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: appLanguage == language.code ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(appLanguage == language.code ? AppColor.accent : AppColor.divider)
                    }
                    .padding(AppSpacing.md)
                    .contentShape(Rectangle())
                }

                if index < languages.count - 1 {
                    Rectangle().fill(AppColor.divider).frame(height: 1)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColor.surface)
                .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
        )
    }

    // MARK: - 언어 변경 (기존 로직 유지)

    private func selectLanguage(_ code: String) {
        appLanguage = code
        AnalyticsManager.log(.languageChanged(language: code))

        // 위젯에도 언어 설정 공유 (별도 프로세스라 App Group으로)
        let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        sharedDefaults?.set(code, forKey: "appLanguage")
        WidgetCenter.shared.reloadAllTimelines()

        // 날씨(주소 포함)를 새 언어로 다시 가져오기
        service.updateWeatherManually()
    }
}

#Preview {
    LanguageView()
        .environmentObject(WeatherService())
        .environmentObject(FontManager())
}
