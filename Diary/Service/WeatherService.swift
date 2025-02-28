//
//  WeatherService.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//

import Foundation
import CoreLocation
import Alamofire
import Combine
import UIKit

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
    
    // Combine의 Cancellable을 사용해 --분마다 자동 업데이트하는 타이머 생성
    //private var timer: AnyCancellable? // combine을 이용한 타이머
    
    // 실행시 위치 권한 요청
    override init() {
        locationManager = CLLocationManager()
        super.init()
        requestLocationPermission()
        
        // 앱 실행 시 강제로 날씨 데이터 가져오기
           DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
               self.updateWeatherManually()
           }
        
        // 10분으로 설정 나중에는 조절해야함 무료플랜 하루 1000회
        // 1분 60 / 1시간 3600
        /*
         timer는 앱이 포그라운드 상태일때만 실행됨
         main 쓰레드에서 실행되기 때문에 백그라운드에서는 동작하지 않음
         포그라운드 활성 상태일 때만 sink가 실행 됨
         그러므로 백그라운드로 전환되면 타이머가 정지됨
         */
//        timer = Timer.publish(every: 600, on: .main, in: .common)
//            .autoconnect()
//            .sink { _ in
//                
//                // 현재 위치 가져오기
//                guard let location = self.locationManager.location else {return}
//                let lat = location.coordinate.latitude
//                let lon = location.coordinate.longitude
//                
//                // timer로 호출된 날씨 확인용 로그
//                let now = Date()
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
//                let currentTime = dateFormatter.string(from: now)
//                
//                print("-------설정 시간마다 자동 업데이트 실행: \(currentTime)------")
//                // 실행
//                self.fetchWeather(lat: lat, lon: lon)
//            }
        
        // 앱이 다시 포그라운드 상태로 돌아오면 최신 날씨 가져오기
        NotificationCenter.default.addObserver(self, selector: #selector(updateWeatherManually), name: UIApplication.willEnterForegroundNotification, object: nil)
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
        
        // 앱 실행 시 강제로 한번 더 위치 업데이트 요청함
        locationManager.requestLocation()
    }
    
    
}



