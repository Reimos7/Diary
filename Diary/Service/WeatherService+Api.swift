//
//  WeatherService+Api.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//

// API를 요청하는 코드
import Foundation
import CoreLocation
import Alamofire

extension WeatherService {
    // API 요청
    func fetchWeather(lat: Double, lon: Double) {
        let url = APIURL.weatherURL
        let parameters: [String: Any] = [
            "lat": lat,
            "lon": lon,
            "appid": APIKey.weatherKey,
            "units": "metric",
            "lang": "kr"
        ]
        // 기존 코드 
        //AF.request(url, method: .get, parameters: parameters)
        
        //URLRequest에 캐싱을 방지하는 헤더 추가.
        AF.request(url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: [
            "Cache-Control": "no-cache",
            "Pragma": "no-cache"
        ])
        .validate(statusCode: 200..<300)
        .responseDecodable(of: CodableCurrentWeather.self) { [weak self] response in
            switch response.result {
            case .success(let weatherData):
                DispatchQueue.main.async {
                    self?.currentWeather = CurrentWeather(data: weatherData)
                    print("------ API 원본 응답 ------")
                    print("응답데이터\(weatherData)")
                    print("-------------------------")
                    
                }
            case .failure(let error):
                print("Weather API Error: \(error.localizedDescription)")
            }
        }
    }
}
