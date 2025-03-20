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
    @State private var selectedDate: Date = Date()
    //날짜 선택시 네비게이션
    @State private var selectedDateNavigate = false
    
    let model: CurrentWeather?
    
    var body: some View {
        NavigationStack {
            // MARK: - 날씨
            WeatherView()
            
            VStack {
                // MARK: - 날짜 선택 시 해당 날짜 다이어리 작성페이지 이동
                NavigationLink(isActive: $selectedDateNavigate) {
                    CalendarComposeView(selectedDate: $selectedDate)
                } label: {
                    EmptyView()
                }
                // 캘린더
                CalendarSetView(selectedDate: $selectedDate, dateSelectAction: { date in
                    selectedDate = date
                    selectedDateNavigate = true
                })
                .frame(minWidth: 400, minHeight: 400)
                .padding()
                
                
                // MARK: - 오늘 글쓰기
                NavigationLink {
                    ComposeView(model: model)
                }           label: {
                    Image("pencil_img")
                        .resizable()
                        .frame(maxWidth: 50,maxHeight: 50)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                }
            }
            .padding()
            Spacer()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingView()
                        } label: {
                            Image("setting_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                            
                        }
                        
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            ListView()
                        } label: {
                            Image("list_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 34, height: 34) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                    }
                }
        }
    }
}
