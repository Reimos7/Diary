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
        AF.request(url, method: .get, parameters: parameters)
            .validate(statusCode: 200..<300)
            .responseDecodable(of: CodableCurrentWeather.self) { [weak self] response in
                switch response.result {
                case .success(let weatherData):
                    DispatchQueue.main.async {
                        self?.currentWeather = Weather(data: weatherData)
                        print("응답데이터\(weatherData)")
                    }
                case .failure(let error):
                    print("Weather API Error: \(error.localizedDescription)")
                }
            }
    }
}
