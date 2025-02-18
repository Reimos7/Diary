//
//  String+WeatherSymbol.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation

// openWeather API에서 지원해주는 날씨 아이콘을 애플 기본 날씨 아이콘으로 변환하는 코드
extension String {
    var weatherImageName: String {
        switch self {
        case "01d":
            return "sun.max.fill"
        case "01n":
            return "moon.fill"
        case "02d":
            return "cloud.sun.fill"
        case "02n":
            return "cloud.moon.fill"
        case "03d", "03n":
            return "cloud.fill"
        case "04d", "04n":
            return "smoke.fill"
        case "09d", "09n":
            return "cloud.rain.fill"
        case "10d":
            return "cloud.sun.rain.fill"
        case "10n":
            return "cloud.moon.rain.fill"
        case "11d", "11n":
            return "cloud.bolt.rain.fill"
        case "13d", "13n":
            return "snowflake"
        case "50d", "50n":
            return "humidity"
        default:
            return "circle"
        }
    }
}
