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
        
        //  캘린더 로케일 설정 (한국어)
        calendar.locale = Locale(identifier: "ko_KR")
        
        //  캘린더 헤더의 날짜 형식
        calendar.appearance.headerDateFormat = "yyyy.MM"
        
        //  캘린더 색상 및 스타일 설정
        calendar.appearance.headerTitleColor = UIColor.black
        calendar.appearance.weekdayTextColor = UIColor.systemGray3
        calendar.appearance.titleDefaultColor = UIColor.black
        calendar.appearance.selectionColor = UIColor(red: 230/255, green: 244/255, blue: 237/255, alpha: 1)
        calendar.appearance.titleTodayColor = UIColor.black
        calendar.appearance.todayColor = UIColor.clear
        calendar.appearance.titleSelectionColor = UIColor.black
        calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        calendar.backgroundColor = UIColor.white
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        // 필요한 업데이트 로직
        uiView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
        var parent: FSCalendarView
        
        init(_ parent: FSCalendarView) {
            self.parent = parent
        }
        
       
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
                    let calendar = Calendar.current
                    let weekday = calendar.component(.weekday, from: date) // 요일 가져오기 (1: 일요일, 7: 토요일)
                    
                    if weekday == 1 || weekday == 7 {
                        return .red  // ✅ 토요일(7)과 일요일(1)은 빨간색으로 표시
                    } else {
                        return .black // ✅ 평일은 검정색
                    }
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
