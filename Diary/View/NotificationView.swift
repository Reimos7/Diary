//
//  NotificationView.swift
//  Diary
//
//  Created by Reimos on 3/29/25.
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
            List {
                Toggle("푸시 알림", isOn: $isOnPushNotification)
                    .onChange(of: isOnPushNotification) { _ , newValue in
                        if newValue {
                            // Toggle on 하면, 앱 권한 설정으로 이동하는 alert 보여주기 
                            // 권한으로 이동해서 설정 유도
                            showPushNotificationAlert = true
                            // 알림 권한 확인 후 일기가 없는 경우 알림 설정
                            // manager를 직접 사용하여 diary entries 접근
                            NotificationManager.shared.checkScheduleNotification(entries: manager.diaryEntries)
                            
                        } else {
                            // Toggle off 하면, 이미 예약된 알림을 취소시켜서 알림을 보내지 않게 하기
                            // 실제 권한 자체는 해제할 수 없기 때문에, 우회적 처리를 하는것이 일반적임
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["diaryReminder"])
                            // 알림 끄기 - 모든 알림 취소
                            NotificationManager.shared.cancelPushNotifications()
                        }
                        
                    }
                
                    .alert("알림 권한이 필요 합니다", isPresented: $showPushNotificationAlert) {
                        Button(role: .cancel) {
                            
                        } label: {
                            Text("취소")
                        }
                        
                        Button {
                            // 앱의 설정 화면을 열어 사용자가 위치 권한을 변경할 수 있도록 유도
                            service.openAppSettings()
                        } label: {
                            Text("확인")
                        }
                        
                    } message: {
                        Text("권한을 허용해 주세요")
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // navigationTitle 대신 커스텀 폰트 적용을 위해 구현
                ToolbarItem(placement: .principal) {
                    Text("알림 설정")
                }
                // 뒤로 가기 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // 뒤로 가기 동작 (현재 뷰 닫기)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(uiColor: UIColor.label))
                    }
                    .tint(.clear) // 버튼에 기본 tint 색(파란색) 무력화
                }
            }
            
        }
    }
}

#Preview {
    NotificationView()
}
