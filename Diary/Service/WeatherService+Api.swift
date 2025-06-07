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
@preconcurrency import WeatherKit

extension WeatherService {
    private static var call = 0
    // API 요청
    func fetchWeather(lat: Double, lon: Double) {
        Self.call += 1
        print(#function, "날씨 API 요청됨: \(Self.call)")
        Task { 
            let location = CLLocation(latitude: lat, longitude: lon)
            
            do {
                let weather = try await service.weather(for: location)
                DispatchQueue.main.async { [weak self] in
                    self?.currentWeather = CurrentWeather(from: weather)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }
}
