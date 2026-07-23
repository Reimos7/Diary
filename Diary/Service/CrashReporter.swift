//
//  CrashReporter.swift
//  Diary
//
//  Firebase Crashlytics 래퍼
//
//  [핵심 개념]
//  - Crashlytics는 FirebaseApp.configure() 이후 크래시를 "자동으로" 수집한다
//    즉 별도 초기화 코드는 필요 없다
//  - 다만 크래시 로그가 유용하려면 "어떤 상황에서 터졌는지" 문맥이 필요하다
//    이 래퍼는 로그 남기기 / 잡힌 에러 기록 / 테스트 크래시를 한 곳에서 제공한다
//
//  [주의]
//  - Crashlytics는 크래시를 "다음 앱 실행 시" 업로드한다
//    따라서 테스트 크래시를 낸 뒤에는 앱을 다시 실행해야 콘솔에 나타난다
//  - Xcode 디버거가 붙어 있으면 크래시를 디버거가 가로채므로,
//    반드시 디버거를 떼고(앱을 직접 실행) 테스트해야 정확히 수집된다
//

import Foundation
import FirebaseCrashlytics

enum CrashReporter {

    // 크래시 리포트에 함께 남길 로그. 크래시 발생 시 이 로그들이 타임라인으로 보인다
    // 예: CrashReporter.log("이미지 저장 시작")
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    // 앱을 죽이지는 않지만 기록해두고 싶은 에러(비치명적 오류)를 남긴다.
    // 예: 이미지 저장 실패, 디코딩 실패 등 catch 블록에서 호출.
    // 크래시가 아니어도 Firebase 콘솔의 "비치명적" 항목에 집계된다.
    static func record(_ error: Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    // 크래시 리포트에 붙는 커스텀 키. 크래시 순간의 앱 상태를 파악하는 데 쓴다.
    // 예: CrashReporter.setValue("Main", forKey: "current_screen")
    static func setValue(_ value: String, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    #if DEBUG
    // 동작 확인 전용 강제 크래시
    // DEBUG 빌드에서만 컴파일되므로 실제 출시 앱에는 절대 포함되지 않는다.
    // 사용법: 설정 화면 등에 임시 버튼을 만들어 호출 → 앱 재실행 → 콘솔 확인.
    static func testCrash() {
        fatalError(" Crashlytics 테스트 크래시 (의도된 것)")
    }
    #endif
}
