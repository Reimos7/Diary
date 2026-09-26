//
//  AnalyticsManager.swift
//  Diary
//
//  Firebase Analytics 이벤트 발송을 한 곳에서 관리하는 래퍼
//
//  [왜 이렇게 감싸는가]
//  - Analytics.logEvent를 화면 곳곳에서 문자열로 직접 호출하면 오타(집계 누락)와
//    규칙 위반(이벤트명 형식)이 발생하기 쉽다
//  - 이벤트를 enum으로 타입 안전하게 정의해 오타를 컴파일 단계에서 차단하고,
//    발송 로직을 이 매니저로 단일화한다
//

import Foundation
import FirebaseAnalytics

// MARK: - 이벤트 정의
// 앱에서 추적할 사용자 행동을 타입 안전하게 정의한다
// associatedValue로 파라미터를 함께 실어 보낸다
enum AnalyticsEvent {
    // 수익화 핵심 이벤트
    case diarySaved(hasImage: Bool, hasWeather: Bool, saveCountToday: Int)  // 일기 저장(오늘 몇 번째인지 포함)
    case composeStarted(entryPoint: String)              // 작성 화면 진입(깔때기 입구)
    case diaryShared(type: String)                       // 공유/캡처(바이럴 지표)

    // 콘텐츠 관리 이벤트
    case diaryDeleted                                    // 일기 삭제
    case diaryUpdated                                    // 일기 수정
    case diarySearched(keyword: String)                  // 검색 실행
    case screenViewed(name: String)                      // 화면 진입

    // 설정/기능 인기도 이벤트
    case themeChanged(theme: String)                     // 테마 변경
    case languageChanged(language: String)               // 언어 변경
    case fontChanged(font: String)                       // 폰트 변경

    // 앱 잠금 이벤트
    //
    // [PIN 값이나 입력한 숫자는 절대 싣지 않는다]
    // 알고 싶은 것은 "이 기능을 얼마나 쓰고, 얼마나 막히는가"이지 사용자의 비밀번호가 아니다.
    // 실패 횟수 같은 집계값만 보낸다.
    case appLockEnabled(biometry: String)                // 잠금 켜기(어떤 생체를 쓸 수 있는 기기인지)
    case appLockDisabled                                 // 잠금 끄기
    case appUnlocked(method: String)                     // 해제 성공(pin/biometry)
    case appUnlockFailed(attempt: Int)                   // 해제 실패(누적 몇 번째 실패인지)
    case pinReset                                        // 생체로 본인 확인 후 PIN 재설정

    // Firebase에 전달될 이벤트 이름.
    // 규칙: 소문자 + 언더스코어, 40자 이내, 예약 접두어(firebase_, google_, ga_) 금지
    var name: String {
        switch self {
        case .diarySaved:     return "diary_saved"
        case .composeStarted: return "compose_started"
        case .diaryShared:    return "diary_shared"
        case .diaryDeleted:   return "diary_deleted"
        case .diaryUpdated:   return "diary_updated"
        case .diarySearched:  return "diary_searched"
        case .screenViewed:   return AnalyticsEventScreenView   // Firebase 표준 화면 이벤트 재사용
        case .themeChanged:   return "theme_changed"
        case .languageChanged:return "language_changed"
        case .fontChanged:    return "font_changed"
        case .appLockEnabled:   return "app_lock_enabled"
        case .appLockDisabled:  return "app_lock_disabled"
        case .appUnlocked:      return "app_unlocked"
        case .appUnlockFailed:  return "app_unlock_failed"
        case .pinReset:         return "pin_reset"
        }
    }

    // 이벤트에 함께 실어 보낼 파라미터
    // 값은 String 또는 NSNumber만 허용
    var parameters: [String: Any]? {
        switch self {
        case let .diarySaved(hasImage, hasWeather, saveCountToday):
            // save_count_today: 오늘 몇 번째 저장인지
            // 나중에 "3번째 저장마다 전면광고" 같은 빈도 제한 설계의 근거
            return [
                "has_image": hasImage ? 1 : 0,
                "has_weather": hasWeather ? 1 : 0,
                "save_count_today": saveCountToday
            ]
        case let .composeStarted(entryPoint):
            // entry_point: 어디서 작성 화면에 진입했는지(main/calendar/widget 등).
            // 작성→저장 전환율(깔때기)을 분석할 때 사용한다.
            return ["entry_point": entryPoint]
        case let .diaryShared(type):
            return ["share_type": type]
        case let .diarySearched(keyword):
            // 검색어 원문을 그대로 보내면 개인정보/카디널리티 문제가 생길 수 있으므로
            // 길이만 지표로 보낸다. (무엇을 검색했는지보다 "검색 기능을 쓰는지"가 중요)
            return ["keyword_length": keyword.count]
        case let .screenViewed(name):
            // Firebase 표준 화면 이벤트 파라미터 키를 사용해야 대시보드에 정상 노출된다.
            return [AnalyticsParameterScreenName: name]
        case let .themeChanged(theme):
            return ["theme": theme]
        case let .languageChanged(language):
            return ["language": language]
        case let .fontChanged(font):
            return ["font": font]
        case let .appLockEnabled(biometry):
            // biometry: face_id / touch_id / none.
            // 생체를 쓸 수 있는 기기에서 실제로 얼마나 켜는지 보려면 기기 종류를 알아야 한다.
            return ["biometry": biometry]
        case let .appUnlocked(method):
            // method: pin / biometry.
            // 생체 비중이 높으면 자동 프롬프트 설계가 잘 먹히고 있다는 뜻이다.
            return ["method": method]
        case let .appUnlockFailed(attempt):
            // 실패가 잦으면 4자리 PIN이나 키패드 UX에 문제가 있다는 신호다.
            return ["attempt": attempt]
        case .diaryDeleted, .diaryUpdated, .appLockDisabled, .pinReset:
            return nil
        }
    }
}

// MARK: - 매니저

enum AnalyticsManager {

    // 이벤트를 Firebase Analytics로 발송한다
    // 호출부는 AnalyticsManager.log(.diarySaved(...)) 형태로만 쓰면 되므로
    /// 문자열/파라미터 규칙을 신경 쓸 필요가 없다
    static func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        #if DEBUG
        print("Analytics: \(event.name) \(event.parameters ?? [:])")
        #endif
    }
}
