//
//  CodableCurrentWeather.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//

import Foundation
// Codable은 Swift에서 JSON 데이터를 쉽게 변환(파싱) 할 수 있도록 도와주는 프로토콜
// Swift의 Encodable과 Decodable 프로토콜을 합친 것으로, JSON을 객체로 변환하거나 객체를 JSON으로 변환할 수 있음

// 날씨 아이콘, 날씨, 온도 
struct CodableCurrentWeather: Codable {
    struct Weather: Codable {
        let description: String
        let icon: String
    }
    let weather: [Weather]
    
    struct Main: Codable {
        let temp: Double
    }
    let main: Main
}
