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
    
    // 현재 날씨 다국어 번역 (String Catalog에서 번역을 찾아서 반환)
    // localizedString() 헬퍼를 사용하여 앱 내 언어 설정에 맞는 번역을 가져옴
    // (내부적으로 LocalizedStringResource + appLocale을 사용)
    //
    // ⚠️ String(localized:locale:)의 locale 파라미터는 번역 선택이 아닌
    //    보간값 포맷팅에만 영향을 주므로, LocalizedStringResource를 사용해야 함
    var koreanDescription: String {
        switch self {
        case .blizzard: return localizedString("눈보라")
        case .blowingDust: return localizedString("황사")
        case .blowingSnow: return localizedString("날림눈")
        case .breezy: return localizedString("산들바람")
        case .clear: return localizedString("맑음")
        case .cloudy: return localizedString("흐림")
        case .drizzle: return localizedString("이슬비")
        case .flurries: return localizedString("눈날림")
        case .foggy: return localizedString("안개")
        case .freezingDrizzle: return localizedString("얼어붙는 이슬비")
        case .freezingRain: return localizedString("얼어붙는 비")
        case .frigid: return localizedString("혹한")
        case .hail: return localizedString("우박")
        case .haze: return localizedString("연무")
        case .heavyRain: return localizedString("호우")
        case .heavySnow: return localizedString("대설")
        case .hot: return localizedString("폭염")
        case .hurricane: return localizedString("허리케인")
        case .isolatedThunderstorms: return localizedString("국지적 뇌우")
        case .mostlyClear: return localizedString("대체로 맑음")
        case .mostlyCloudy: return localizedString("대체로 흐림")
        case .partlyCloudy: return localizedString("부분적으로 흐림")
        case .rain: return localizedString("비")
        case .scatteredThunderstorms: return localizedString("산발적 뇌우")
        case .sleet: return localizedString("진눈깨비")
        case .smoky: return localizedString("깊은 안개")
        case .snow: return localizedString("눈")
        case .strongStorms: return localizedString("강한 폭풍우")
        case .sunFlurries: return localizedString("햇살 속 눈날림")
        case .sunShowers: return localizedString("햇살 속 소나기")
        case .thunderstorms: return localizedString("뇌우")
        case .tropicalStorm: return localizedString("열대폭풍")
        case .windy: return localizedString("강풍")
        case .wintryMix: return localizedString("겨울 혼합강수")
        @unknown default: return localizedString("알 수 없음")
        }
    }
}
