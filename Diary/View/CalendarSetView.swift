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
    //@Environment(\.colorScheme) var colorScheme  // 다크 모드 감지
    @EnvironmentObject var manager: SwiftDataManager
    @Binding var selectedDate: Date
    // 캘린더에서 날짜 직접 선택 시 실행할 콜백 함수
    var dateSelectAction: ((Date) -> Void)?
    
    func makeUIView(context: Context) -> FSCalendar {
        
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
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
        // FSCalendar는 UIKit 컴포넌트이기 때문에, traitCollection을 이용하면 정확한 시점에 정확한 스타일을 적용 (colorScheme X)
        let isDarkMode = calendar.traitCollection.userInterfaceStyle == .dark
        
        // 캘린더 배경 색상
        // 이전 달, 다음 달 버튼 숨기기
        calendar.appearance.headerMinimumDissolvedAlpha = 0 // 내비게이션 화살표 숨기기
        // 캘린더 로케일 설정 (한국어)
        calendar.locale = Locale(identifier: "ko_KR")
        // 셀 크기 조정
        calendar.rowHeight = 80
        // 캘린더 헤더의 날짜 형식
        calendar.appearance.headerDateFormat = "yyyy년 M월"
        
        // 범위 설정 (월 단위 범위만 보이도록 설정)
        calendar.scope = .month
        calendar.backgroundColor = isDarkMode ? UIColor.black : UIColor.white
        calendar.appearance.headerTitleColor = isDarkMode ? UIColor.white : UIColor.black
        //calendar.appearance.weekdayTextColor = isDarkMode ? UIColor.white : UIColor.black
        calendar.appearance.titleDefaultColor = isDarkMode ? UIColor.white : UIColor.black
        //calendar.appearance.titleWeekendColor = isDarkMode ? UIColor.red.withAlphaComponent(0.8) : UIColor.red
        // 선택한 날짜 기본 스타일 제거
        calendar.appearance.selectionColor = .clear
        //calendar.appearance.titleSelectionColor = isDarkMode ? UIColor.white : UIColor.black
        calendar.appearance.subtitleSelectionColor = isDarkMode ? UIColor.white : UIColor.black
        
        // 오늘 날짜 스타일 (푸른색 테두리, 흰색 글자)
        //calendar.appearance.todayColor = UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0)
        //calendar.appearance.todayColor = UIColor.white
        //calendar.appearance.titleTodayColor = UIColor.white // 오늘 날짜 글자 흰색
        //calendar.appearance.subtitleTodayColor = UIColor.white // "오늘" 글자도 흰색
        //calendar.appearance.borderSelectionColor = UIColor.clear
        
        calendar.appearance.todayColor = .clear
        calendar.appearance.titleTodayColor = calendar.appearance.titleDefaultColor
        // 오늘 날짜 하단 "오늘" 텍스트 색상 다크모드 대응
        calendar.appearance.subtitleTodayColor = isDarkMode ? UIColor.white : UIColor.black
        // "오늘" 글자 내리기
        calendar.appearance.subtitleOffset = CGPoint(x: 0, y: 5)
        calendar.appearance.selectionColor = .clear
        // 일요일은 항상 red, 토요일은 blue 평일은 라이트 모드 black, 다크모드 white
        calendar.calendarWeekdayView.weekdayLabels.enumerated().forEach { index, label in
            switch index {
            case 0:  // 일요일
                label.textColor = .systemRed
            case 6:  // 토요일
                label.textColor = .systemBlue
            default:
                label.textColor = isDarkMode ? .white : .black
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
        
        // 현재 페이지(월)가 바뀌었을 때 호출되는 델리게이트 메서드
        // 캘린더를 좌우로 스와이프해서 이전 달 / 다음 달로 이동할때 실행
        func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                // 다크모드/라이트모드에 따른 외관 재적용
                self.parent.updateCalendarAppearance(calendar)
                calendar.setNeedsLayout()
                calendar.layoutIfNeeded()
                // 강제 리로드로 월 전환 후 스타일 적용
                calendar.reloadData()
            }
        }
        
        // 특정 날짜에 일기가 저장된 경우, 점으로 표시
        @MainActor func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return parent.manager.hasDiaryentry(for: date) ? 1 : 0
        }
        // 이벤트 점 색상을 빨간색으로 변경
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
            return [UIColor.red]
        }
        
        // 캘린더 날짜 색상 적용 함수
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
            
            // 현재 캘린더가 보여주고 있는 달
            let currentMonth = Calendar.current.component(.month, from: calendar.currentPage)
            // 선택한 날짜의 달
            let targetMonth = Calendar.current.component(.month, from: date)
            // 선택한 날짜의 요일
            let weekday = Calendar.current.component(.weekday, from: date)
            
            // 현재 달이 아닌 이전/다음 달 날짜는 회색 유지
            if currentMonth != targetMonth {
                return UIColor.lightGray
            }
            switch weekday {
            case 1: return .systemRed      // 일요일
            case 7: return .systemBlue     // 토요일
            default:
                return calendar.traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
        }
        // 날짜 선택 시 콜백 호출
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.selectedDate = date
            parent.dateSelectAction?(date) // 콜백 호출
        }
        
        // 사용자가 날짜를 선택하려고 할때, 해당 날짜가 선택 가능한지 판단
        func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
            // 오늘 이후 날짜를 비활성화(선택 불가) 처리
            return date <= Date()
        }
        
        // "오늘"을 현재 날짜 아래에 표시
        func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
            let today = Date()
            if Calendar.current.isDate(date, inSameDayAs: today) {
                return "오늘"
            }
            return nil
        }
        
        // 사용자가 날짜를 선택했을 때, 해당 날짜 숫자의 색상을 결정하는 함수
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleSelectionColorFor date: Date) -> UIColor? {
            // 현재 캘린더가 보여주고 있는 달
            let currentMonth = Calendar.current.component(.month, from: calendar.currentPage)
            // 선택한 날짜의 달
            let targetMonth = Calendar.current.component(.month, from: date)
            // 선택한 날짜의 요일
            let weekday = Calendar.current.component(.weekday, from: date)
            
            // 현재 달이 아닌 이전/다음 달 날짜는 회색 유지
            if currentMonth != targetMonth {
                return UIColor.lightGray
            }
            
            // 요일에 따라 색상 다르게 설정
            switch weekday {
            case 1: // 일요일
                return UIColor.systemRed
            case 7:  // 토요일
                return UIColor.systemBlue
            default:
                return calendar.appearance.titleDefaultColor // 평일: 기본 색
            }
        }
        
        // 선택한 날짜의 . 색상 무조건 빨강으로
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]? {
            return [UIColor.red]
        }
        
        // 선택된 날짜 처리
        //        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillSelectionColorFor date: Date) -> UIColor? {
        //            //return UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0) // 오늘 날짜와 동일한 색상 적용
        //            //return UIColor(red: 0.3569, green: 0.8824, blue: 1, alpha: 1.0)
        //            return UIColor.clear
        //
        //        }
    }
}
