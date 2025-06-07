//
//  CurrentWeather.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
import WeatherKit
// MainView의 상단에서 보여줄 날씨
struct CurrentWeather{
    //let name: String // 지역 명
    let icon: String
    let weather: String
    let temperature: String
    let maxTemperature: String
    let minTemperature: String
    let sunrise: String
    let sunset: String
}

// 프리뷰용 데이터
extension CurrentWeather {
    static var preview: CurrentWeather {
        return CurrentWeather(icon: "sun.max.fill",
                              weather: "맑음",
                              temperature: Double.randomTempertureString,
                              maxTemperature: Double.randomTempertureString,
                              minTemperature: Double.randomTempertureString,
                              sunrise: "오전 6:00",
                              sunset: "오후 6:00")
    }
    
    init(from weather: Weather) {
        let current = weather.currentWeather
        let daily = weather.dailyForecast.forecast.first
        // 낮과 밤에 따라 날씨 아이콘 적용 
        self.icon = current.condition.sfSymbolName(isDaylight: current.isDaylight)
        print(self.icon)
        self.weather = current.condition.koreanDescription
        print(self.weather)
        self.temperature = current.temperature.value.temperatureString
        self.maxTemperature = daily?.highTemperature.value.temperatureString ?? "--"
        self.minTemperature = daily?.lowTemperature.value.temperatureString ?? "--"
        
        // 일출 및 일몰 시간은 local 시간으로 변환
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "a h:mm"
        
        if let sunriseDate = daily?.sun.sunrise {
            self.sunrise = formatter.string(from: sunriseDate)
        } else {
            self.sunrise = "--"
        }
        
        if let sunsetDate = daily?.sun.sunset {
            self.sunset = formatter.string(from: sunsetDate)
        } else {
            self.sunset = "--"
        }
        
    }
}


