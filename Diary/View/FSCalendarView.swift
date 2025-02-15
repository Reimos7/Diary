//
//  FSCalendarView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import SwiftUI
import FSCalendar

struct FSCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    
    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // 캘린더 커스터마이징
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.appearance.selectionColor = .systemPurple
        calendar.appearance.todayColor = .systemBlue
        calendar.appearance.headerTitleColor = .label
        calendar.appearance.weekdayTextColor = .gray
        
        
        calendar.appearance.headerDateFormat = "YYYY년 MM월"
        
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // 필요한 업데이트 로직
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var parent: FSCalendarView
        
        init(_ parent: FSCalendarView) {
            self.parent = parent
        }
        
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.selectedDate = date
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date() // ✅ State 변수 추가

        var body: some View {
            FSCalendarView(selectedDate: $selectedDate) // ✅ Binding 전달
        }
    }
    
    return PreviewWrapper()
}
