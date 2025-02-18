//
//  ComposeView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import SwiftUI

struct ComposeView: View {
    //@Binding var selectedDate: Date
    // 현재 날짜
    @State private var currentDate = Date()
    var body: some View {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy년 M월 d일 EEEE" // 요일 포함
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter
        }()
        
        NavigationStack {
            VStack {
//                Image(systemName: DummyContainer.preview.weatherIcon)
//                    .resizable()
//                    .frame(width: 50, height: 50)
//                    .padding()
                Text(dateFormatter.string(from: Date())) // 2025년 2월 5일 (수요일)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        
                    } label: {
                        Label("Save", systemImage: "check")
                    }
                    
                }
            }
        }
    }
        
}

#Preview {
    ComposeView()
}
