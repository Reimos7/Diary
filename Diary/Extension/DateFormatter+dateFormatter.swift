//
//  DateFormatter.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import Foundation

// MARK: - 지원 언어 목록
// 앱이 지원하는 언어 코드 목록
// String Catalog(Localizable.xcstrings)에 번역이 있는 언어만 포함
// 이 목록에 없는 언어의 사용자에게는 영어("en")로 fallback
let supportedLanguages: Set<String> = ["ko", "en", "ja"]

// MARK: - 앱 언어 설정에 연동되는 Locale 헬퍼
// SwiftUI의 .environment(\.locale)은 Text 뷰에만 적용됨
// DateFormatter, CLGeocoder, FSCalendar 등 Foundation/UIKit API에는
// 이 헬퍼를 통해 직접 Locale을 전달해야 함
//
// 동작 방식:
// 1. UserDefaults에 "appLanguage" 값이 있으면 → 사용자가 앱 내에서 선택한 언어
// 2. 없으면 → 아이폰 시스템 언어 확인
// 3. 시스템 언어가 지원 목록에 있으면 → 그 언어 사용
// 4. 시스템 언어가 지원 목록에 없으면 → 영어("en")로 fallback
//
// 예시:
// - 한국 아이폰 → "ko" (지원) → 한국어
// - 프랑스 아이폰 → "fr" (미지원) → "en" 영어로 fallback
// - 일본 아이폰 → "ja" (지원) → 일본어
var appLocale: Locale {
    let code = UserDefaults.standard.string(forKey: "appLanguage")
        ?? resolvedSystemLanguage()
    return Locale(identifier: code)
}

// 시스템 언어가 앱 지원 목록에 있는지 확인하고,
// 없으면 영어로 fallback하는 함수
func resolvedSystemLanguage() -> String {
    let systemCode = Locale.current.language.languageCode?.identifier ?? "en"
    // 시스템 언어가 지원 목록에 있으면 그대로 사용, 없으면 영어로 fallback
    return supportedLanguages.contains(systemCode) ? systemCode : "en"
}

// MARK: - 앱 언어 설정에 맞는 번역 문자열 반환 헬퍼
// String(localized:locale:)의 locale 파라미터는 보간값 포맷팅에만 영향을 주고,
// 실제 번역 언어 선택에는 영향을 주지 않음.
// LocalizedStringResource를 사용하면 locale에 맞는 번역을 정확히 가져올 수 있음.
//
// 사용 예시:
//   localizedString("오늘")     → appLocale에 맞게 "오늘" / "Today" / "今日"
//   localizedString("흐림")     → appLocale에 맞게 "흐림" / "Cloudy" / "曇り"
func localizedString(_ key: String.LocalizationValue) -> String {
    return String(localized: LocalizedStringResource(key, locale: appLocale))
}

extension DateFormatter {

    // 로케일에 맞게 날짜 표시 (한: "2026년 2월 28일 금요일" / 영: "Friday, February 28, 2026")
    // static let → static var: 언어 변경 시 매번 새 locale로 생성되어야 하므로
    // (static let은 앱 실행 시 한 번만 생성되어 언어 변경이 반영되지 않음)
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMMM d EEEE")
        return formatter
    }

    // 알림용 날짜 (한: "2월 28일" / 영: "Feb 28" / 일: "2月28日")
    static var dateScheduleNotificationFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter
    }

    // 시간 표시 (한: "오후 02:30" / 영: "2:30 PM" / 일: "午後02:30")
    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = appLocale
        formatter.setLocalizedDateFormatFromTemplate("a hh:mm")
        return formatter
    }
}
