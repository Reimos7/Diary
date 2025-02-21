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
            VStack() {
                // 메인화면에서 날씨 연동해주기
                Text(service.currentLocation ?? "없음")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                //Spacer()
                /*
                 WeatherService가 API에서 받아온 데이터를 currentWeather에 저장하면,
                 @EnvironmentObject var service를 통해 MainView에서 실시간으로 반영됨
                 */
                
                if let model = service.currentWeather {
                    VStack(alignment: .leading) {
                        HStack {
                            if model.icon != "moon.fill" {
                                Image(systemName: model.icon)
                                    .font(.largeTitle)
                                // 아이콘 심볼 이미지를 멀티 컬러 색상으로
                                    .symbolRenderingMode(.multicolor)
                                    .onAppear {
                                        print("아이콘이 적용됨 \(model.icon)")
                                    }
                            } else {
                                Image(systemName: model.icon)
                                    .font(.largeTitle)
                                // 아이콘 심볼 이미지를 멀티 컬러 색상으로
                                // moon.fill이면 멀티 컬러 안됨
                                //.symbolRenderingMode(.multicolor)
                                    .onAppear {
                                        print("아이콘이 적용됨 \(model.icon)")
                                    }
                            }
                            
                            Text(model.weather)
                            Text(model.temperature)
                            
                            //Spacer()
                        }
                        .padding()
                        .font(.largeTitle)
                        //.frame(height: reader.size.height)
                    }
                }
             }
            .padding()
            
            VStack {
                // MARK: - 날짜 선택 시 해당 날짜 다이어리 작성페이지 이동
                NavigationLink(isActive: $selectedDateNavigate) {
                    FSCalenderComposeView(selectedDate: selectedDate)
                } label: {
                    EmptyView()
                }
                // 캘린더
                FSCalendarView(selectedDate: $selectedDate, dateSelectAction: { date in
                    selectedDate = date
                    selectedDateNavigate = true
                })
                .frame(width: 400, height: 400)
                .padding()
                
                
                // MARK: - 오늘 글쓰기
                NavigationLink {
                    ComposeView(model: model)
                }           label: {
                    Image(systemName: "pencil")
                        .resizable()
                        .frame(width: 50, height: 50)
                    
                }
            }
            .padding()
            Spacer()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink {
                            SettingView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                        }
                        
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            ListView()
                        } label: {
                            Image(systemName: "list.bullet")
                        }
                    }
                }
        }
    }
}

