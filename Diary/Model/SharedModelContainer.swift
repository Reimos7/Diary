//
//  SharedModelContainer.swift
//  Diary
//
//  Created by Reimos on 11/5/25.
//

import SwiftData
import Foundation

// 메인 앱과 위젯이 공유하는 ModelContainer를 생성하는 유틸리티
enum SharedModelContainer {
    // App Group Identifier - 메인 앱과 위젯이 데이터를 공유하기 위한 식별자
    // Xcode에서 App Groups Capability를 메인 앱과 위젯 타겟 모두에 추가해야 함
    static let appGroupIdentifier = "group.com.reimos7.goodd.diary"

    // 공유 ModelContainer 생성
    // - Returns: 메인 앱과 위젯에서 공통으로 사용할 ModelContainer
    static func create() -> ModelContainer {
        let schema = Schema([
            Diary.self,
        ])

        // App Group을 사용하여 컨테이너 저장 위치 지정
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(appGroupIdentifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create shared ModelContainer: \(error)")
        }
    }
}
