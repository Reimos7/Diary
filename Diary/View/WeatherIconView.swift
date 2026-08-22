//
//  WeatherIconView.swift
//  Diary
//
//  날씨를 손그림 커스텀 아이콘으로 표시하는 재사용 컴포넌트.
//  저장된 SF Symbol 이름을 커스텀 에셋으로 매핑하고, 매핑이 없으면 기존 SF Symbol로 폴백한다.
//  상세·홈·작성·기록·캘린더 등 날씨를 보여주는 모든 곳에서 공통 사용.
//

import SwiftUI

struct WeatherIconView: View {
    /// 저장된 날씨 심볼(SF Symbol 이름). 예: "sun.max.fill"
    let symbol: String?
    /// 표시 크기.
    var size: CGFloat = 48

    var body: some View {
        if let asset = Self.customAsset(for: symbol) {
            // 손그림 커스텀 아이콘
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else if let symbol {
            // 매핑 없는 날씨(안개/바람/천둥 등)는 기존 SF Symbol 유지
            Image(systemName: symbol)
                .symbolRenderingMode(.multicolor)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// SF Symbol 이름 → 커스텀 손그림 에셋 이름. 매핑 없으면 nil(폴백).
    static func customAsset(for symbol: String?) -> String? {
        guard let s = symbol else { return nil }
        switch true {
        // 눈 계열
        case s.contains("snow"), s.contains("snowflake"), s.contains("sleet"), s.contains("hail"):
            return "weather_snow"
        // 천둥번개
        case s.contains("bolt"):
            return "weather_thunder"
        // 비 계열
        case s.contains("rain"), s.contains("drizzle"), s.contains("heavyrain"):
            return "weather_rain"
        // 바람/태풍 계열
        case s.contains("wind"), s.contains("hurricane"), s.contains("tropicalstorm"), s.contains("tornado"):
            return "weather_wind"
        // 구름 조금 (낮/밤)
        case s.contains("cloud.sun"):
            return "weather_cloudy_day"
        case s.contains("cloud.moon"):
            return "cloudy_night"
        // 안개/연무/먼지/스모그 → 구름만 아이콘으로 대체
        case s.contains("fog"), s.contains("haze"), s.contains("smoke"), s.contains("dust"), s.contains("mist"):
            return "weather_cloudy"
        // 흐림(구름만)
        case s.contains("cloud"):
            return "weather_cloudy"
        // 맑음 (낮/밤)
        case s.contains("moon"):
            return "clear_night"
        case s.contains("sun"):
            return "weather_clear_day"
        default:
            // 그 외(온도계 등 특수) → SF Symbol 폴백
            return nil
        }
    }

    /// SF Symbol 이름 → 번역된 날씨 설명 (맑음/비/흐림…).
    /// 이 앱은 시스템 언어가 아니라 SwiftUI 환경 locale(.environment(\.locale, ...))로 언어를 바꾸므로,
    /// String(localized:)이 아니라 LocalizedStringKey로 반환해 Text가 환경 locale로 번역하게 한다.
    /// (String으로 반환 후 Text(변수)에 넣으면 번역되지 않고 한글로 고정됨)
    /// 매핑 없는 날씨는 nil을 돌려 호출부에서 Text 자체를 그리지 않는다.
    static func description(for symbol: String?) -> LocalizedStringKey? {
        guard let s = symbol else { return nil }
        switch true {
        case s.contains("snow"), s.contains("snowflake"), s.contains("sleet"), s.contains("hail"):
            return "눈"
        case s.contains("bolt"):
            return "천둥번개"
        case s.contains("rain"), s.contains("drizzle"), s.contains("heavyrain"):
            return "비"
        case s.contains("fog"), s.contains("haze"), s.contains("smoke"), s.contains("dust"), s.contains("mist"):
            return "안개"
        case s.contains("wind"), s.contains("hurricane"), s.contains("tropicalstorm"), s.contains("tornado"):
            return "바람"
        case s.contains("cloud.sun"), s.contains("cloud.moon"):
            return "구름 조금"
        case s.contains("cloud"):
            return "흐림"
        case s.contains("sun"), s.contains("moon"):
            return "맑음"
        default:
            return nil
        }
    }
}
