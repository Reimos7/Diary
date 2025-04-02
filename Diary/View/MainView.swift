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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: WeatherService
    @State private var selectedDate: Date = Date()
    //날짜 선택시 네비게이션
    @State private var selectedDateNavigate = false
    
    let model: CurrentWeather?
    
    var body: some View {
        NavigationStack {
            // MARK: - 날씨
            WeatherView()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 2)
                .padding(.top , -10)
            
            VStack {
                // 캘린더
                CalendarSetView(selectedDate: $selectedDate, dateSelectAction: { date in
                    selectedDate = date
                    selectedDateNavigate = true
                })
                .frame(maxWidth: .infinity)
                .frame(height: 400)

                Spacer()
                
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
            
            // MARK: - 날짜 선택 시 해당 날짜 다이어리 작성페이지 이동
            .navigationDestination(isPresented: $selectedDateNavigate, destination: {
                CalendarComposeView(selectedDate: $selectedDate)
            })
            .padding()
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
            // 위치 권한 거부 시 alert 표시
                .alert("위치 정보 권한 필요", isPresented: $service.showLocationDeniedAlert) {
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("취소")
                    }
                    
                    Button {
                        // 앱의 설정 화면을 열어 사용자가 위치 권한을 변경할 수 있도록 유도
                        service.openAppSettings()
                    } label: {
                        Text("확인")
                    }
                    
                } message: {
                    Text("앱 사용을 위해 설정에서 위치 권한을 허용해주세요.")
                }
        }
    }
}
