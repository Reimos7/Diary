//
//  ComposeView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import SwiftUI

// 글쓰기 버튼 누르면 실행 되는 뷰 (오늘 날짜만)
struct ComposeView: View {
    @EnvironmentObject var service: WeatherService
    @State private var content: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    
    let model: CurrentWeather?
    
    var body: some View {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일 EEEE" // 요일 포함
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter
        }()
        
        NavigationStack {
            VStack {
                if let model = service.currentWeather {
                    Image(systemName: model.icon)
                    // 아이콘 심볼 이미지를 멀티 컬러 색상으로
                        //.symbolRenderingMode(.multicolor)
                        .resizable()
                        .frame(width: 50,height: 50)
                        .onAppear() {
                            print("\(model.icon)")
                        }
                }
                
                Text(dateFormatter.string(from: Date())) // 2025년 2월 5일 (수요일)
                // 입력을 위한 TextEditor
                TextEditor(text: $content)
                    .padding()
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        manager.addDiaryData(content: content, date: Date())
                        manager.fetchDiaryData()
                        dismiss()
                    } label: {
                        Label("Save", systemImage: "checkmark")
                    }
                    
                }
            }
        }
    }
    
}

//#Preview {
//    ComposeView(model: .preview)
//}
