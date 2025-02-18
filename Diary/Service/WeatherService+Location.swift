//
//  WeatherService+Location.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//

import Foundation
import CoreLocation

// WeatherService가 CLLocationManagerDelegate를 확장(Extension)하여 위치 관련 기능을 추가함
extension WeatherService: CLLocationManagerDelegate {
    
    private func updateAddress(from location: CLLocation) async throws -> String {
        
        // CLGeocoder 객체 생성 (리버스 지오 코딩을 위한 도구)
        let geocoder = CLGeocoder()
        
        // 지정된 위도/경도를 한국어(Ko_kr)로 변환
        let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "Ko_kr"))
        
        // placemarks에 접근해서 주소 정보를 빼옴
        if let placemark = placemarks.first {
            // 우리나라 기준 "구"에 해당하는 값은 locality 속성에 있고, "동"에 해당하는 값은 subLocality 속성에 저장됨
            if let gu = placemark.locality, let dong = placemark.subLocality {
                return "\(gu) \(dong)" // 변환된 주소 반환 (ex: 강남구 삼성동)
            } else {
                // 구,동이 아닌 다른형태 -> 외국 등등
                return placemark.name ?? "알수없음"
            }
        }
        // placemark 정보가 없을 경우 기본값 반환
        return "알수없음"
    }
    
    // 위치 데이터를 처리하는 함수 (위치 데이터를 받아서 주소로 변환)
    /*
     1.    location(위도/경도)을 받아서 주소(구 + 동)로 변환 (updateAddress(from:) 호출)
     2.    변환된 주소를 self.currentLocation에 저장 (UI에서 현재 위치 표시)
     3.    변환이 실패하면 self.lastError에 에러 메시지를 저장
     */
    private func process(location: CLLocation) {
        // Task 메인 스레드를 차단하지 않고 백그라운드에서 실행
        // // 백그라운드에서 실행할 비동기 작업 시작
        Task {
            do {
                // 비동기 함수 updateAddress(from:)가 완료될 때까지 기다린 후, 결과 값을 address에 저장
                // 비동기 주소 변환 (오래 걸릴 수도 있음)
                let address = try await updateAddress(from: location)
                // UI 업데이트는 항상 메인 스레드에서 실행해야 함
                // UI 업데이트를 위한 코드이므로 반드시 메인 스레드에서 실행해야 함
                // 변환된 주소를 currentLocation에 저장 (UI에서 표시)
                DispatchQueue.main.async {
                    self.currentLocation = address
                }
            } catch {
                print("주소 변환 실패: \(error.localizedDescription)")
                // 에러 메시지 저장 (UI에서 에러 표시 가능)
                self.lastError = error.localizedDescription
            }
        }
    }
    
    // 위치 정보 업데이트
    // 자표를 처리하는 코드
    // 좌표는 마지막 파라미터로 전달되고,배열 마지막 부분에 들어 있다
    // 위치 업데이트가 발생할 때 실행되는 함수 (위치가 변경될 때 마다 호출됨)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 최신 위치 정보 가져오기 (배열의 마지막 요소)
        guard let location = locations.last else {return}
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        //현재 위치 처리
        process(location: location)
        
        //위치 업데이트 후 날씨 정보 가져오기
        fetchWeather(lat: lat, lon: lon)
        // 위치 업데이트가 끝나면, 더이상 위치를 받지 않도록 중지 (위치 업데이트 중지) 배터리도 절약됨
        manager.stopUpdatingLocation()
    }
    
    // 위치 권한 상태 변경 처리
    // 위치 권한이 변경될 때 호출되는 함수 (사용자가 위치 권한을 허용했는지 확인)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            // 위치 서비스 권한이 "항상 허용", "앱 사용중 허용" 일 경우에 현재 위치 요청
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
            // 아직 사용자가 위치 권한을 설정하지 않은 경우
        case .notDetermined:
            lastError = "위치 서비스 사용 권한을 확인할 수 없습니다."
            // 사용자가 위치 권한을 '거부' 했거나 '제한됨' (자녀 보호 설정 같은 이유들로..)
        case .denied, .restricted:
            lastError = "위치 서비스 사용 권한이 없습니다."
            // 기타 예상하지 못한 경우
        default:
            lastError = "알 수 없는 오류가 발생 했습니다."
        }
    }
    // 에러가 발생하면 locationManager를 중지하고, 에러 메시지를 저장함
    // 위치 정보를 가져오는 중 오류가 발생했을때 실행됨
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // 위치 업데이트 중지
        manager.startUpdatingLocation()
        // 발생한 에러 메시지 저장
        lastError = error.localizedDescription
    }
}
