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
    // 런타임에 사용하는거니까, 프리뷰 파라미터를 사용하지 않고, false값을 그대로 사용
    let service = WeatherService()
    @StateObject private var manager = SwiftDataManager()
    
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
            MainView(model: .preview)
        }
        .modelContainer(sharedModelContainer)
        // WeatherService는 앱 전체에서 공통적으로 사용하는거니까, environmentObject로 공유 하는게 좋음
            .environmentObject(service)
            .environmentObject(manager)
    
    }
}
