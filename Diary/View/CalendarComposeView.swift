//
//  FSCalenderComposeView.swift
//  Diary
//
//  Created by Reimos on 2/19/25.
//

import SwiftUI

// MARK: - 사용자가 캘린더에서 날짜를 선택하면 실행
struct CalendarComposeView: View {
    //let selectedDate: Date
    @State private var content: String = ""
    @State private var showToast: Bool = false
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        VStack {
            // 캘린더에서 선택한 날짜를 보여줌
            Text(DateFormatter.dateFormatter.string(from:selectedDate))
            // 입력을 위한 TextEditor
            TextEditor(text: $content)
                .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    manager.addDiaryData(content: content, date: selectedDate)
                    showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showToast = false
                        dismiss()
                    }
                } label: {
                    Image("checkmark_img")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24) // SF Symbol 크기와 유사하게 조정
                        .foregroundColor(.primary)
                }
                
            }
        }
        // 저장하면 toast 메시지로 알려줌
        if showToast {
            VStack {
                Text("일기를 저장했어요!")
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .transition(.opacity)
            .animation(.easeInOut, value: showToast)
            .padding(.bottom, 50)
            
        }
        
        // .navigationTitle(dateFormatter.string(from: selectedDate))
    }
}

