//
//  DiaryApp.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct DiaryApp: App {
    // Firebase 초기화를 담당하는 AppDelegate를 SwiftUI 생명주기에 연결한다
    // 이 선언이 있어야 AppDelegate.application(_:didFinishLaunchingWithOptions:)가 실제로 호출
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // 런치 스크린 표시 여부
    @State private var isShowingLaunchScreen: Bool = true

    // 저장된 테마 상태 - 처음은 시스템으로 시작
    @AppStorage("selectedTheme") private var selectedTheme: ThemeOption = .system

    // 사용자가 선택한 앱 언어 (기본값: 시스템 언어 또는 영어 fallback)
    // 이 값이 바뀌면 .environment(\.locale)을 통해 앱 전체 UI가 즉시 새 언어로 다시 그려짐
    //
    // @AppStorage의 기본값은 앱 최초 실행 시에만 사용됨
    // 이후에는 UserDefaults에 저장된 값을 자동으로 읽음
    //
    // 기본값 결정 로직 (resolvedSystemLanguage):
    // - 시스템 언어가 지원 목록(ko, en, ja)에 있으면 -> 그 언어
    // - 시스템 언어가 지원 목록에 없으면 -> "en" (영어 fallback)
    @AppStorage("appLanguage") private var appLanguage: String = resolvedSystemLanguage()

    @StateObject private var service = WeatherService()

    @StateObject private var manager = SwiftDataManager()
    // 폰트 변경
    @StateObject private var fontManager = FontManager()

    @Environment(\.scenePhase) private var scenePhase

    // 위젯에서 딥링크로 전달받을 상태
    @State private var shouldNavigateToCompose: Bool = false
    
    // 위젯과 공유하는 ModelContainer
    var sharedModelContainer: ModelContainer = SharedModelContainer.create()

    // 앱 최초 실행 시 위젯용 App Group UserDefaults에도 언어 설정을 동기화
    // 위젯은 별도 프로세스라 앱의 UserDefaults를 직접 읽을 수 없으므로
    // App Group을 통해 공유해야 함
    init() {
        let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        // App Group에 언어 설정이 없으면 (앱 최초 실행) 현재 앱 언어를 저장
        if sharedDefaults?.string(forKey: "appLanguage") == nil {
            sharedDefaults?.set(appLanguage, forKey: "appLanguage")
        }
    }

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
                    // 메인 뷰 표시 (새 디자인: 탭바)
                    GlobalFontView(size: 16) {
                        MainTabView(shouldNavigateToCompose: $shouldNavigateToCompose)
                    }
                    // 폰트 매니저
                    .environmentObject(fontManager)
                    .preferredColorScheme(getColorScheme())
                    // 위젯에서 딥링크로 앱 열기
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
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

                            // 위젯 갱신
                            WidgetCenter.shared.reloadAllTimelines()

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
        // appLanguage 값이 바뀌면 SwiftUI가 전체 뷰를 새 언어로 즉시 다시 렌더링
        .environment(\.locale, Locale(identifier: appLanguage))
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

    // 딥링크 처리 함수
    private func handleDeepLink(_ url: URL) {
        print("딥링크 수신: \(url)")

        // diary://compose 형태로 전달됨
        if url.scheme == "diary", url.host == "compose" {
            print("일기 작성 화면으로 이동")
            // 런치 스크린 종료 후 네비게이션
            isShowingLaunchScreen = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shouldNavigateToCompose = true
            }
        }
    }
}
