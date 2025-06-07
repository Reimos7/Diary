//
//  String+WeatherSymbol.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
import WeatherKit

extension WeatherCondition {
    // 낮/밤에 따라 다른 아이콘 제공
    func sfSymbolName(isDaylight: Bool) -> String {
        switch self {
        case .clear: return isDaylight ? "sun.max.fill" : "moon.stars.fill"
        case .mostlyClear: return isDaylight ? "cloud.sun.fill" : "moon.stars.fill"
        case .partlyCloudy: return isDaylight ? "cloud.sun.fill" : "cloud.moon.fill"
        case .mostlyCloudy: return isDaylight ? "cloud.fill" : "cloud.moon.fill"
        case .sunShowers: return isDaylight ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .sunFlurries: return isDaylight ? "cloud.sun.snow.fill" : "cloud.moon.snow.fill"
        default:
            // 나머지 날씨 
            switch self {
            case .blizzard: return "wind.snow"
            case .blowingDust: return "sun.dust.fill"
            case .blowingSnow: return "wind.snow"
            case .breezy: return "wind"
            case .cloudy: return "cloud.fill"
            case .drizzle: return "cloud.drizzle.fill"
            case .flurries: return "cloud.snow.fill"
            case .foggy: return "cloud.fog.fill"
            case .freezingDrizzle: return "cloud.sleet.fill"
            case .freezingRain: return "cloud.sleet.fill"
            case .frigid: return "thermometer.snowflake"
            case .hail: return "cloud.hail.fill"
            case .haze: return "sun.haze.fill"
            case .heavyRain: return "cloud.heavyrain.fill"
            case .heavySnow: return "cloud.snow.fill"
            case .hot: return "thermometer.sun.fill"
            case .hurricane: return "hurricane.circle.fill"
            case .isolatedThunderstorms: return "cloud.bolt.rain.fill"
            case .rain: return "cloud.rain.fill"
            case .scatteredThunderstorms: return "cloud.bolt.rain"
            case .sleet: return "cloud.sleet.fill"
            case .smoky: return "smoke.fill"
            case .snow: return "snowflake"
            case .strongStorms: return "cloud.bolt.rain.fill"
            case .thunderstorms: return "cloud.bolt.rain.fill"
            case .tropicalStorm: return "tropicalstorm"
            case .windy: return "wind"
            case .wintryMix: return "wind"
            @unknown default: return "questionmark"
            }
        }
    }
    
    // 현재 날씨 한국어 번역
    var koreanDescription: String {
        switch self {
        case .blizzard: return "눈보라"
        case .blowingDust: return "황사"
        case .blowingSnow: return "날림눈"
        case .breezy: return "산들바람"
        case .clear: return "맑음"
        case .cloudy: return "흐림"
        case .drizzle: return "이슬비"
        case .flurries: return "눈날림"
        case .foggy: return "안개"
        case .freezingDrizzle: return "얼어붙는 이슬비"
        case .freezingRain: return "얼어붙는 비"
        case .frigid: return "혹한"
        case .hail: return "우박"
        case .haze: return "연무"
        case .heavyRain: return "호우"
        case .heavySnow: return "대설"
        case .hot: return "폭염"
        case .hurricane: return "허리케인"
        case .isolatedThunderstorms: return "국지적 뇌우"
        case .mostlyClear: return "대체로 맑음"
        case .mostlyCloudy: return "대체로 흐림"
        case .partlyCloudy: return "부분적으로 흐림"
        case .rain: return "비"
        case .scatteredThunderstorms: return "산발적 뇌우"
        case .sleet: return "진눈깨비"
        case .smoky: return "깊은 안개"
        case .snow: return "눈"
        case .strongStorms: return "강한 폭풍우"
        case .sunFlurries: return "햇살 속 눈날림"
        case .sunShowers: return "햇살 속 소나기"
        case .thunderstorms: return "뇌우"
        case .tropicalStorm: return "열대폭풍"
        case .windy: return "강풍"
        case .wintryMix: return "겨울 혼합강수"
        @unknown default: return "알 수 없음"
        }
    }
}
