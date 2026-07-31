//
//  MainTabView.swift
//  Diary
//
//  앱의 루트 탭바. 홈 · 캘린더 · 기록 · 설정 4개 탭으로 구성.
//  위젯 딥링크(shouldNavigateToCompose)는 홈 탭으로 전달해 작성 화면을 연다.
//

import SwiftUI

struct MainTabView: View {
    @Binding var shouldNavigateToCompose: Bool
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(shouldNavigateToCompose: $shouldNavigateToCompose)
                .tabItem { Label("홈", systemImage: "house") }
                .tag(0)

            CalendarView()
                .tabItem { Label("캘린더", systemImage: "calendar") }
                .tag(1)

            ListView()
                .tabItem { Label("기록", systemImage: "list.bullet") }
                .tag(2)

            SettingView()
                .tabItem { Label("설정", systemImage: "gearshape") }
                .tag(3)
        }
        // 선택된 탭 색 = 포인트(더스티 블루)
        .tint(AppColor.accent)
        // 위젯 딥링크가 오면 홈 탭으로 전환 (홈에서 작성 화면을 연다)
        .onChange(of: shouldNavigateToCompose) { _, newValue in
            if newValue { selectedTab = 0 }
        }
    }
}

#Preview {
    MainTabView(shouldNavigateToCompose: .constant(false))
        .environmentObject(WeatherService())
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
