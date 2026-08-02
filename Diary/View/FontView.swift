//
//  FontView.swift
//  Diary
//
//  Created by Reimos on 4/15/25.
//  새 디자인: 종이 배경 + 상단 미리보기 카드 + 폰트 선택 그룹 카드.
//  폰트 변경 로직/Analytics는 기존 그대로. 날씨는 공유 데이터 재사용(API 추가 호출 없음).
//

import SwiftUI

struct FontView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var service: WeatherService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    previewCard
                    fontCard
                }
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("폰트 설정")
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

    // MARK: - 상단 미리보기 (선택 폰트로 표시)

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

            Text("매일 매일이 행복한 하루가 되길 바랄게\n행복한 일상을 '굿디'와 함께 기록해 보자")
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

    // MARK: - 폰트 선택 카드

    private var fontCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(FontManager.fontList.enumerated()), id: \.element) { index, font in
                Button {
                    fontManager.changeFont(to: font)
                    AnalyticsManager.log(.fontChanged(font: font))
                } label: {
                    HStack {
                        Text(FontManager.displayName(for: font))
                            .customFont(size: 16)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        Image(systemName: fontManager.currentFont == font ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(fontManager.currentFont == font ? AppColor.accent : AppColor.divider)
                    }
                    .padding(AppSpacing.md)
                    .contentShape(Rectangle())
                }

                if index < FontManager.fontList.count - 1 {
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
}

#Preview {
    FontView()
        .environmentObject(FontManager())
        .environmentObject(WeatherService())
}
