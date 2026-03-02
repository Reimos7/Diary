//
//  WeatherService+Location.swift
//  Diary
//
//  Created by Reimos on 2/17/25.
//
import CoreLocation
import UIKit

// WeatherService가 CLLocationManagerDelegate를 확장(Extension)하여 위치 관련 기능을 추가함
extension WeatherService: CLLocationManagerDelegate {
    
    private func updateAddress(from location: CLLocation) async throws -> String {
        
        // CLGeocoder 객체 생성 (리버스 지오 코딩을 위한 도구)
        let geocoder = CLGeocoder()
        
        // 앱 언어 설정에 맞게 위도/경도를 주소로 변환
        let placemarks = try await geocoder.reverseGeocodeLocation(location, preferredLocale: appLocale)
        
        // placemarks에 접근해서 주소 정보를 빼옴
        if let placemark = placemarks.first {
            // 우리나라 기준 "구"에 해당하는 값은 locality 속성에 있고, "동"에 해당하는 값은 subLocality 속성에 저장됨
            if let gu = placemark.locality, let dong = placemark.subLocality {
                return "\(gu) \(dong)" // 변환된 주소 반환 (ex: 강남구 삼성동)
            } else {
                // 구,동이 아닌 다른형태 -> 외국 등등
                return placemark.name ?? localizedString("알수없음")
            }
        }
        // placemark 정보가 없을 경우 기본값 반환
        return localizedString("알수없음")
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
                DispatchQueue.main.async { [weak self] in
                    self?.currentLocation = address
                }
            } catch {
                print("주소 변환 실패: \(error.localizedDescription)")
                // 에러 메시지 저장 (UI에서 에러 표시 가능)
                //self.lastError = error.localizedDescription
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
            // 위치 권한이 허용된 경우 weatherView를 즉시 변경 해줌
            showLocationDeniedWeatherView = false
            
            // 아직 사용자가 위치 권한을 설정하지 않은 경우
        case .notDetermined:
            // 사용자가 권한 설정을 하지 않았다면 권한 설정 팝업 띄어주면서 사용 유도 
            locationManager.requestWhenInUseAuthorization()
            
            self.lastError = String(localized: "위치 서비스 사용 권한을 확인할 수 없습니다.")
            // 사용자가 위치 권한을 '거부' 했거나 '제한됨' (자녀 보호 설정 같은 이유들로..)
        case .denied, .restricted:
            /*  위치 권한이 거부된 상태에서 CLLocationManager가 오류를 지속적으로 발생시키거나 이벤트 루프를 점유 하면 UIKit 터치 이벤트 전달이 정상적으로 안될 가능성이 크다 -> 그러므로 거부된 상태에서 CLLocationManager 동작을 완전히 중단 시켜야 함, 위치 권한이 거부된 상태에서 startUpdatingLocation()이 실행되고 있으면 내부적으로 delegate에서 didFailWithError가 반복적으로 호출되면서 UI 이벤트 루프를 방해함
             */
            locationManager.stopUpdatingLocation()
            // 위치 권한이 거부된 경우 currentLocation을 nil로 설정
            currentLocation = nil
            // 위치 권한이 거부된 경우 currentWeather을 nil로 설정
            currentWeather = nil
            showLocationDeniedWeatherView = true
            showLocationDeniedAlert = true
            // 권한 거부된 경우 알림 표시
            locationDeniedWeatherView()
            LocationPermissionDeniedAlert()
            
            lastError = String(localized: "위치 서비스 사용 권한이 없습니다.")
            // 기타 예상하지 못한 경우
        default:
            lastError = String(localized: "알 수 없는 오류가 발생 했습니다.")
        }
        
        
    }
    
    // 에러가 발생하면 locationManager를 중지하고, 에러 메시지를 저장함
    // 위치 정보를 가져오는 중 오류가 발생했을때 실행됨
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        // 실패 핸들러에서도 stopUpdatingLocation() 추가해야 함
        manager.stopUpdatingLocation()
        // 발생한 에러 메시지 저장
        lastError = error.localizedDescription
    }
    //  강제로 새 API 호출
    @objc func updateWeatherManually() {
        if let location = locationManager.location {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            //fetchWeather(lat: lat, lon: lon)
            // 더 정확한 위치를 호출
            locationManager.requestLocation()
            print(#function)
            print("현재 요청된 위도: \(lat), 경도: \(lon)")
        }
    }
    
    // 위치 권한을 위해 앱 설정 페이지로 이동하는 메서드
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // 권한 거부된 경우 알림 표시
    func LocationPermissionDeniedAlert() {
        showLocationDeniedAlert = true
    }
    
    
    // 위치가 거부된 경우 weatherView 변경
    func locationDeniedWeatherView() {
        showLocationDeniedWeatherView = true 
    }
    
}
