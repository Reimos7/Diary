//
//  FontView.swift
//  Diary
//
//  Created by Reimos on 4/15/25.
//

import SwiftUI

struct FontView: View {
    
    let data: Diary
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var service: WeatherService
    
    var body: some View {
        // ComposeView를 통해 현재 날씨 아이콘을 가져오게 되면 보여주기
        ZStack {
            // 위치 권한이 거부된 상태라면
            if service.showLocationDeniedWeatherView {
                Text("위치 권한을 허용하면 날씨를 기록할 수 있어요!\n")
            } else {
                if let model = service.currentWeather {
                    Image(systemName: model.icon)
                        .resizable()
                        .frame(width: 82, height: 72)
                        .offset(x: 1, y: 1)
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    Image(systemName: model.icon)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .frame(width: 80, height: 70)
                        .onAppear {
                            print(model.icon)
                        }
                }
            }/*else if service.showLocationDeniedWeatherView {
              Text("위치 권한을 허용하면 날씨를 기록할 수 있어요!\n")
              }*/
        }
        .shadow(radius: 2)
        
        Text(DateFormatter.dateFormatter.string(from: Date.now))
            .padding()
            .foregroundStyle(.secondary)
            .customFont(size: 16)
        
        Text("매일 매일이 행복한 하루가 되길 바랄게\n행복한 일상을 '굿디'와 함께 기록해 보자")
            .padding()
        
        Divider()
        
        List {
            ForEach(FontManager.fontList, id: \.self) { font in
                Button {
                    fontManager.changeFont(to: font)
                } label: {
                    HStack {
                        Text(FontManager.displayName(for: font))
                        Spacer()
                        // 선택된 폰트에 체크 표시 추가
                        Image(systemName: fontManager.currentFont == font ? "circle.circle.fill" : "circle")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        //.frame(maxWidth: .infinity, alignment: .leading)
        //.padding()
        .listStyle(.plain)
        .navigationTitle("폰트 설정")
        .navigationBarTitleDisplayMode(.inline)
        // 기본 뒤로 가기 버튼 숨김
        .navigationBarBackButtonHidden()
        // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
        .background(NavigationControllerWrapper())
        
        .toolbar {
            // 뒤로 가기 버튼
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    // 뒤로 가기 동작 (현재 뷰 닫기)
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(uiColor: UIColor.label))
                }
                .tint(.clear) // 버튼에 기본 tint 색(파란색) 무력화
            }
        }
    }
}

