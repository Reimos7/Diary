//
//  NotificationView.swift
//  Diary
//
//  Created by Reimos on 3/29/25.
//  새 디자인: 종이 배경 + 카드형 토글. 로직(알림 예약/권한)은 기존 그대로.
//

import SwiftUI
import UserNotifications

struct NotificationView: View {
    @AppStorage("isPushNotificationEnabled") private var isOnPushNotification: Bool = false
    @State private var showPushNotificationAlert: Bool = false
    @EnvironmentObject var service: WeatherService
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // 알림 토글 카드
                    HStack(spacing: AppSpacing.md) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppColor.calendarPastels[0])
                            .frame(width: 38, height: 38)
                            .overlay(
                                Image("notification_img")
                                    .resizable().scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(AppColor.textPrimary)
                            )

                        Text("푸시 알림")
                            .customFont(size: 16)
                            .foregroundStyle(AppColor.textPrimary)

                        Spacer()

                        Toggle("", isOn: $isOnPushNotification)
                            .labelsHidden()
                            .tint(AppColor.accent)
                    }
                    .padding(AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(AppColor.surface)
                            .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                    )

                    // 안내 문구
                    Text("오늘 일기를 쓰지 않은 날, 저녁에 잊지 않도록 알려드려요.")
                        .customFont(size: 13)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppSpacing.xs)
                }
                .padding(AppSpacing.lg)
            }
            .paperBackground()
            .onChange(of: isOnPushNotification) { _, newValue in
                if newValue {
                    showPushNotificationAlert = true
                    NotificationManager.shared.checkScheduleNotification(entries: manager.diaryEntries)
                } else {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["diaryReminder"])
                    NotificationManager.shared.cancelPushNotifications()
                }
            }
            .alert("알림 권한이 필요 합니다", isPresented: $showPushNotificationAlert) {
                Button("취소", role: .cancel) {}
                Button("확인") { service.openAppSettings() }
            } message: {
                Text("권한을 허용해 주세요")
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("알림 설정")
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
}

#Preview {
    NotificationView()
        .environmentObject(WeatherService())
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
