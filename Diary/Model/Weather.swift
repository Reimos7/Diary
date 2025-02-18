//
//  CurrentWeather.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
// MainView의 상단에서 보여줄 날씨
struct Weather: Decodable {
    //let name: String // 지역 명
    let icon: String
    let weather: String
    let temperature: String
}

// 프리뷰용 데이터
extension Weather {
    static var preview: Weather {
        return Weather(icon: "sun.max.fill", weather: "맑음", temperature: Double.randomTempertureString)
    }
    
    init?(data: CodableCurrentWeather) {
        guard let weatherInfo = data.weather.first else {return nil}
        
        // icon에 sfSymbol 넣기
        icon = weatherInfo.icon.weatherImageName
        weather = weatherInfo.description
        temperature = data.main.temp.temperatureString
    }
}


