//
//  ThemeView.swift
//  Diary
//
//  Created by Reimos on 3/18/25.
//  새 디자인: 종이 배경 + 그룹 카드 선택 목록. 테마 변경 로직은 기존 그대로.
//

import SwiftUI

struct ThemeView: View {
    @AppStorage("selectedTheme") private var selectedTheme: ThemeOption = .system
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    themeRow(.system, icon: "circle.lefthalf.filled", title: "시스템 설정", color: AppColor.calendarPastels[4])
                    rowDivider
                    themeRow(.light, icon: "sun.max.fill", title: "라이트 모드", color: AppColor.calendarPastels[1])
                    rowDivider
                    themeRow(.dark, icon: "moon.fill", title: "다크 모드", color: AppColor.calendarPastels[0])
                }
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(AppColor.surface)
                        .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                )
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(getColorScheme())
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("테마 설정")
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

    // MARK: - 테마 선택 행

    private func themeRow(_ theme: ThemeOption, icon: String, title: LocalizedStringKey, color: Color) -> some View {
        Button {
            selectTheme(theme)
        } label: {
            HStack(spacing: AppSpacing.md) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(AppColor.textPrimary)
                    )

                Text(title)
                    .customFont(size: 16)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer()

                // 선택 표시
                Image(systemName: selectedTheme == theme ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTheme == theme ? AppColor.accent : AppColor.divider)
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(AppColor.divider)
            .frame(height: 1)
    }

    private func selectTheme(_ theme: ThemeOption) {
        selectedTheme = theme
        AnalyticsManager.log(.themeChanged(theme: theme.rawValue))
    }

    private func getColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// 선택 가능한 테마 Enum (UserDefaults 저장 가능하도록 `String` 타입 지정)
enum ThemeOption: String, CaseIterable {
    case system, light, dark
}

#Preview {
    ThemeView()
        .environmentObject(FontManager())
}
