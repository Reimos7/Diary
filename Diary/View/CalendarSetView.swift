//
//  FSCalendarView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//
import SwiftUI
import FSCalendar

// MARK: - 커스텀 캘린더 설정
struct CalendarSetView: UIViewRepresentable {
    @Environment(\.colorScheme) var colorScheme  // 다크 모드 감지
    @EnvironmentObject var manager: SwiftDataManager
    @Binding var selectedDate: Date
    // 캘린더에서 날짜 직접 선택 시 실행할 콜백 함수
    var dateSelectAction: ((Date) -> Void)?
    
    func makeUIView(context: Context) -> FSCalendar {
        
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // 캘린더 로케일 설정 (한국어)
        calendar.locale = Locale(identifier: "ko_KR")
        // 셀 크기 조정
        calendar.rowHeight = 80
        // 캘린더 헤더의 날짜 형식
        calendar.appearance.headerDateFormat = "yyyy년 M월"
        
        // 범위 설정 (월 단위 범위만 보이도록 설정)
        calendar.scope = .month
        
        // 이전 달, 다음 달 버튼 숨기기
        calendar.appearance.headerMinimumDissolvedAlpha = 0 // 내비게이션 화살표 숨기기
        
        // 다크 모드와 라이트 모드에 따른 색상 설정
        updateCalendarAppearance(calendar)
        
        return calendar
    }
    
    func updateUIView(_ uiView: FSCalendar, context: Context) {
        updateCalendarAppearance(uiView)
        uiView.reloadData()
    }
    
    /// 다크 모드 여부에 따라 캘린더 색상을 동적으로 업데이트하는 함수
    func updateCalendarAppearance(_ calendar: FSCalendar) {
        let isDarkMode = colorScheme == .dark
        
        // 캘린더 배경 색상
        calendar.backgroundColor = isDarkMode ? UIColor.black : UIColor.white
        calendar.appearance.headerTitleColor = isDarkMode ? UIColor.white : UIColor.black
        //calendar.appearance.weekdayTextColor = isDarkMode ? UIColor.white : UIColor.black
        calendar.appearance.titleDefaultColor = isDarkMode ? UIColor.white : UIColor.black
        calendar.appearance.titleWeekendColor = isDarkMode ? UIColor.red.withAlphaComponent(0.8) : UIColor.red
        
        // 오늘 날짜 스타일 (푸른색 테두리, 흰색 글자)
        calendar.appearance.todayColor = UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0)
        calendar.appearance.titleTodayColor = UIColor.white // 오늘 날짜 글자 흰색
        calendar.appearance.subtitleTodayColor = UIColor.white // "오늘" 글자도 흰색
        calendar.appearance.borderSelectionColor = UIColor.clear
        
        // 일요일은 항상 red / 다른 요일은 라이트 모드 black, 다크모드 white
        calendar.calendarWeekdayView.weekdayLabels.enumerated().forEach { index, label in
            if index == 0 {
                label.textColor = UIColor.red
            } else {
                label.textColor = isDarkMode ? UIColor.white : UIColor.black
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var parent: CalendarSetView
        
        init(_ parent: CalendarSetView) {
            self.parent = parent
        }
        
        // 특정 날짜에 일기가 저장된 경우, 점으로 표시
        @MainActor func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return parent.manager.hasDiaryentry(for: date) ? 1 : 0
        }
        // 이벤트 점 색상을 빨간색으로 변경
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
            return [UIColor.red]
        }
        
        
        // 날짜 선택 시 콜백 호출
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.selectedDate = date
            parent.dateSelectAction?(date) // 콜백 호출
        }
        
        // "오늘"을 현재 날짜 아래에 표시
        func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
            let today = Date()
            if Calendar.current.isDate(date, inSameDayAs: today) {
                return "오늘"
            }
            return nil
        }
        
        // 선택된 날짜 처리
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
            //return UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0) // 오늘 날짜와 동일한 색상 적용
            return UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0)
        }
    }
}
