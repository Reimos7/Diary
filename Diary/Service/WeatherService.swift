//
//  WeatherService.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//

import Foundation
import CoreLocation
import Alamofire

// 날씨 API 및 위치 설정
class WeatherService: NSObject, ObservableObject {
    // location으로 좌표를 얻은 다음에 좌표를 주소로 바꿔서 표시
    let locationManager: CLLocationManager
    
    // 현재 위치
    @Published var currentLocation: String?
    // 현재 날씨
    @Published var currentWeather: CurrentWeather?
    // 에러 문자열을 저장하는 속성
    @Published var lastError: String?
    
    // 실행시 위치 권한 요청
    override init() {
        locationManager = CLLocationManager()
        super.init()
        requestLocationPermission()
    }
    // 위치 권한 설정
    // 사용자의 위치 접근 권한을 요청하고, 이후 위치 정보를 받아오도록 설정
    private func requestLocationPermission() {
        // 위치 매니저의 델리게이트를 현재 클래스(WeatherService)로 설정
        locationManager.delegate = self
        // 사용자가 앱을 실행할 때만 위치 사용 권한 요청
        locationManager.requestWhenInUseAuthorization()
        // 위치 업데이트 시작
        locationManager.startUpdatingLocation()
    }
    
    
}



