//
//  WeatherView.swift
//  Diary
//
//  Created by Reimos on 2/27/25.
//

import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var service: WeatherService
    
    var body: some View {
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
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    Text(model.weather)
                        .font(.body)
                        .padding(.bottom, -8)
                    
                    HStack(alignment: .lastTextBaseline) {
                        Text(model.temperature)
                            .font(.system(size: 110))
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
                            .font(.footnote)
                        Spacer()
                        Image(systemName: "sunrise.fill")
                            .symbolRenderingMode(.multicolor)
                        Text(model.sunrise)
                            .font(.footnote)
                        
                        Image(systemName: "sunset.fill")
                            .symbolRenderingMode(.multicolor)
                        Text(model.sunset)
                            .font(.footnote)
                    }
                }
            }
            .padding()
        }
        .foregroundStyle(.white)
        .padding()
    }
}

#Preview {
    WeatherView()
        .environmentObject(WeatherService())
}
