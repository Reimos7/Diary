//
//  ContentView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI
import SwiftData
import FSCalendar

struct MainView: View {
    @EnvironmentObject var service: WeatherService
    
    let model: Weather?
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                // 메인화면에서 날씨 연동해주기 
                if let model = model {
                    HStack {
                        Text(service.currentLocation ?? "없음")
                        Image(systemName: model.icon)
                        
                        Text(model.temperature)
                        Text(model.weather)
                        Spacer()
                    }
                    .padding()
                    .font(.largeTitle)
                }
            }
            
            VStack {
                // 캘린더
                FSCalendarView(selectedDate: $selectedDate)
                    .frame(width: 400, height: 400)
                    .padding()
                
                NavigationLink {
                    ComposeView()
                }           label: {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 50, height: 50)
                    
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    
                }
            }
        }
        
        
    }
}
#Preview {
    MainView(model: .preview)
    
}

