//
//  CurrentWeather.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
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
    
    init?(data: CodableCurrentWeather) {
        guard let weatherInfo = data.weather.first else {return nil}
        // 디버깅 코드 추가
            print("API 응답 아이콘 코드: \(weatherInfo.icon)")

        // icon에 sfSymbol 넣기
        icon = weatherInfo.icon.weatherImageName
        weather = weatherInfo.description
        temperature = data.main.temp.temperatureString
        maxTemperature = data.main.temp_max.temperatureString
        minTemperature = data.main.temp_min.temperatureString
        // 날짜는 유닉스 시간으로 되어있음
        var date = Date(timeIntervalSince1970: data.sys.sunrise)
        sunrise = date.formatted(.dateTime.hour().minute())
        
        date = Date(timeIntervalSince1970: data.sys.sunset)
        sunset = date.formatted(.dateTime.hour().minute())
        // 변환된 아이콘 코드 확인
           print("변환된 SF Symbol: \(icon)")
    }
}


