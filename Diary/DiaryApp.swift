//
//  DiaryApp.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI
import SwiftData

@main
struct DiaryApp: App {
    // 런치 스크린 표시 여부
    @State private var isShowingLaunchScreen: Bool = true
    
    // 저장된 테마 상태 - 처음은 시스템으로 시작
    @AppStorage("selectedTheme") private var selectedTheme: ThemeOption = .system
    
    @StateObject private var service = WeatherService()
    
    @StateObject private var manager = SwiftDataManager()
    // 폰트 변경
    @StateObject private var fontManager = FontManager()
    
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Diary.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isShowingLaunchScreen {
                    // 런치 스크린만 표시
                    LaunchScreenView()
                        .environmentObject(service) //  강제 초기화 유도
                        .transition(.opacity)
                        .onAppear() {
                            // 1초 후에 런치 스크린 숨기기 -> 너무 길면 안됨
                            print("런치 스크린 표시 - 날씨 업데이트 전")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    isShowingLaunchScreen = false
                                    //print("런치 스크린 종료 후 날씨 업데이트 시작 ")
                                    //service.updateWeatherManually()
                                }
                            }
                        }
                } else {
                    // 메인 뷰 표시
                    GlobalFontView(size: 16) {
                        MainView(model: .preview)
                    }
                    // 폰트 매니저
                    .environmentObject(fontManager)
                    .preferredColorScheme(getColorScheme())
                                        
                    .onChange(of: scenePhase) { _, newPhase in
                        switch newPhase {
                        case .active:
                            print("앱이 활성화됨 - 날씨 업데이트")
                            
                            // 알림 설정이 켜져 있을 때만 처리
                            if UserDefaults.standard.bool(forKey: "isPushNotificationEnabled") {
                                // 알림 권한 요청
                                NotificationManager.shared.requestAutorization()
                                // 알림 조건 확인
                                NotificationManager.shared.checkScheduleNotification(entries: manager.diaryEntries)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                service.updateWeatherManually()
                            }
                            
                        case .inactive:
                            print("앱이 비활성화 됨")
                            
                            
                        case .background:
                            print("앱이 백그라운드로 이동함")
                            
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
        // WeatherService는 앱 전체에서 공통적으로 사용하는거니까, environmentObject로 공유 하는게 좋음
        .environmentObject(service)
        .environmentObject(manager)
    }
    // 현재 선택된 테마를 적용하는 함수
    private func getColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil  // 시스템 설정을 그대로 따름
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
