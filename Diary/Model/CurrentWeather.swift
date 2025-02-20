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
}

// 프리뷰용 데이터
extension CurrentWeather {
    static var preview: CurrentWeather {
        return CurrentWeather(icon: "sun.max.fill", weather: "흐리임", temperature: Double.randomTempertureString)
    }
    
    init?(data: CodableCurrentWeather) {
        guard let weatherInfo = data.weather.first else {return nil}
        // 디버깅 코드 추가
            print("API 응답 아이콘 코드: \(weatherInfo.icon)")

        // icon에 sfSymbol 넣기
        icon = weatherInfo.icon.weatherImageName
        weather = weatherInfo.description
        temperature = data.main.temp.temperatureString
        // 변환된 아이콘 코드 확인
           print("변환된 SF Symbol: \(icon)")
    }
}


