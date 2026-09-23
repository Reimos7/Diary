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

    // MARK: - 앱 잠금 플래그

    // 앱 잠금이 켜져 있는지 위젯에 알리는 App Group 키.
    // 위젯은 별도 프로세스라 Keychain을 볼 수 없고 봐서도 안 되므로,
    // "잠금이 켜져 있다"는 사실만 여기로 전달받아 내용을 가린다.
    // (이 파일은 앱·위젯 양쪽 타깃에 포함되므로 키를 한 곳에서 공유할 수 있다)
    static let appLockEnabledKey = "isAppLockEnabled"

    // 위젯이 일기 내용을 가려야 하는가.
    //
    // App Group 컨테이너에 접근하지 못하는 경우(기기 잠금 중 파일 보호 등)에는
    // "잠금 꺼짐"이 아니라 "가린다"를 기본값으로 삼는다.
    // 읽기 실패를 개방 쪽으로 해석하면, 정작 기기가 잠겨 있을 때 일기가 노출된다.
    static var isAppLockEnabled: Bool {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return true }
        return sharedDefaults.bool(forKey: appLockEnabledKey)
    }

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
