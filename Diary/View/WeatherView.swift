//
//  WeatherView.swift
//  Diary
//
//  Created by Reimos on 2/27/25.
//

import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var service: WeatherService
    // 권한이 없다면 버튼 활성화를 통해 설정 이동 / 권한이 있다면 버튼 비활성화
    var body: some View {
        Button {
            service.openAppSettings()
        } label: {
            // 위치 권한 거부 / 현재 위치가 없는 경우
            if service.showLocationDeniedWeatherView {
                ZStack {
                    // 배경 그라데이션 (크기 자동 조절)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.5),
                            Color.blue.opacity(1.0)
                        ]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                    .cornerRadius(20)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text( "사용자 위치 권한이 필요합니다\n터치를 통해 위치 권한을 허용해 주세요\n날씨 정보를 가져올게요!")
                    }
                    .padding()
                }
                .foregroundStyle(.white)
                .padding()
            }
            else {
                // 현재 위치가 있는 경우
                ZStack {
                    // 배경 그라데이션 (크기 자동 조절)
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.5),
                            Color.blue.opacity(1.0)
                        ]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .edgesIgnoringSafeArea(.all)
                    .cornerRadius(20)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if let model = service.currentWeather {
                            
                            HStack {
                                Text(service.currentLocation ?? "없음")
                                    .customFont(size: 22)
                                    .bold()
                                Spacer()
                            }
                            
                            Text(model.weather)
                                .customFont(size: 17)
                                .padding(.bottom, -8)
                            
                            HStack(alignment: .lastTextBaseline) {
                                Text(model.temperatureAttributed)
                                    .customFont(size: 110)
                                    .fontWeight(.ultraLight)
                                    .minimumScaleFactor(0.5)
                                Spacer()
                                
                                Image(systemName: model.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 140, maxHeight: 140)
                                    .symbolRenderingMode(.multicolor)
                            }
                            
                            HStack {
                                Text("최고 \(model.maxTemperature) | 최저 \(model.minTemperature)")
                                    .customFont(size: 13)
                                Spacer()
                                
                                Image(systemName: "sunrise.fill")
                                    .symbolRenderingMode(.multicolor)
                                Text(model.sunrise)
                                    .customFont(size: 13)
                                
                                Image(systemName: "sunset.fill")
                                    .symbolRenderingMode(.multicolor)
                                Text(model.sunset)
                                    .customFont(size: 13)
                            }
                        }
                    }
                    .padding()
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        // 현재 위치가 있을 경우 버튼을 비활성화
        // disabled가 true라면 버튼 클릭 x
        .disabled(service.currentLocation != nil)
        
        
    }
}

#Preview {
    WeatherView()
        .environmentObject(WeatherService())
}
