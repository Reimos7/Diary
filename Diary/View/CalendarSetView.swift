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
    @EnvironmentObject var manager: SwiftDataManager
    @Binding var selectedDate: Date
    // 캘린더에서 날짜 직접 선택 시 실행할 콜백 함수
    var dateSelectAction: ((Date) -> Void)?
    
    
    func makeUIView(context: Context) -> FSCalendar {
        
        let calendar = FSCalendar()
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        //  캘린더 로케일 설정 (한국어)
        calendar.locale = Locale(identifier: "ko_KR")
        // 셀 크기 조정
        calendar.rowHeight = 80
        //  캘린더 헤더의 날짜 형식
        calendar.appearance.headerDateFormat = "yyyy.MM"
        
        //  캘린더 색상 및 스타일 설정
        calendar.appearance.headerTitleColor = UIColor.black
        calendar.appearance.weekdayTextColor = UIColor.systemGray3
        //calendar.appearance.titleDefaultColor = UIColor.black
        calendar.appearance.selectionColor = UIColor(red: 230/255, green: 244/255, blue: 237/255, alpha: 1)
        calendar.appearance.titleTodayColor = .black
        calendar.appearance.subtitleFont = UIFont.systemFont(ofSize: 10)
        //calendar.appearance.subtitleDefaultColor = UIColor.blue
        calendar.appearance.todayColor = UIColor(red: 230/255, green: 244/255, blue: 237/255, alpha: 1)
        calendar.appearance.titleSelectionColor = UIColor.black
        calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        calendar.backgroundColor = UIColor.white
        
        // 평일 & 주말 색상 설정
        calendar.appearance.titleDefaultColor = UIColor.black  // 평일
        calendar.appearance.titleWeekendColor = UIColor.red    // 주말
        calendar.appearance.subtitleFont = UIFont.systemFont(ofSize: 12)
        calendar.appearance.subtitleOffset = CGPoint(x: 0, y: 10) // 🔹 subtitle 위치 조정
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
        var parent: CalendarSetView
        
        init(_ parent: CalendarSetView) {
            self.parent = parent
        }
        
        // 특정 날짜에 일기가 저장된 경우, 점으로 표시
        @MainActor func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
            return parent.manager.hasDiaryentry(for: date) ? 1 : 0
        }
        
//        func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
//                   let dateFormatter = DateFormatter()
//                   dateFormatter.dateFormat = "yyyy-MM-dd"
//                   let todayString = dateFormatter.string(from: Date())
//                   let targetDateString = dateFormatter.string(from: date)
//                   
//                   if todayString == targetDateString {
//                       return "오늘"
//                   }
//                
//                   return nil
//               }
            
        // ✅ 오늘 날짜에 "오늘"을 표시하는 코드
//        func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {}
//            let dateFormatter = DateFormatter()
//            //let dateFormatter = DateFormatter()
//               dateFormatter.dateFormat = "yyyy-MM-dd"
//               dateFormatter.locale = Locale(identifier: "ko_KR")
//               
//               let todayString = dateFormatter.string(from: Date()) // 오늘 날짜 문자열
//               let targetDateString = dateFormatter.string(from: date) // 캘린더의 특정 날짜 문자열
//
//               if todayString == targetDateString {
//                   return "오늘"
//               }
//               return nil
//            
//            switch dateFormatter.string(from: date) {
//            case dateFormatter.string(from: Date.now):
//                       return "nil"
//                   case "2020-06-22":
//                       return "출근"
//                   case "2020-06-23":
//                       return "지각"
//                   case "2020-06-24":
//                       return "결근"
//                   default:
//                       return "오늘"
//                   }
//            let today = Calendar.current.startOfDay(for: Date()) // 오늘 날짜 (시간 제외)
//            let targetDate = Calendar.current.startOfDay(for: date) // 캘린더 날짜 (시간 제외)
//            
//            return today == targetDate ? "오늘" : nil
            //                        let today = Date()
            //                        let calendar = Calendar.current
            //
            //                        if calendar.isDate(date, inSameDayAs: today) {
            //                            return "오늘" // ✅ 오늘 날짜 밑에 "오늘" 표시
            //                        }
           // return nil
            //            switch dateFormatter.string(from: date) {
            //            case dateFormatter.string(from: Date.now):
            //                      return "오늘"
            //                  default:
            //                      return nil
            //                  }
            //               dateFormatter.dateFormat = "yyyyMMdd" // 날짜를 비교할 형식 지정
            //               dateFormatter.locale = Locale(identifier: "ko_KR") // 한국 로케일 설정
            //
            //               let todayString = dateFormatter.string(from: Date()) // 오늘 날짜 문자열 변환
            //               let dateString = dateFormatter.string(from: date) // 캘린더의 특정 날짜 문자열 변환
            //
            //               if dateString == todayString {
            //                   return "오늘" // ✅ 오늘 날짜에 "오늘" 표시
            //               }
            //               return nil
            //            let dateFormatter = DateFormatter()
            //            let today = Date()
            //                        let calendar = Calendar.current
            //            switch dateFormatter.string(from: date) {
            //            case dateFormatter.string(from: Date()):
            //                return "오늘"
            //            case: calendar.isDate(date, inSameDayAs: today) {
            //                return "오늘"
            //            }
            //            default:
            //                return nil
            //            }
            //            let today = Date()
            //            let calendar = Calendar.current
            //
            //            if calendar.isDate(date, inSameDayAs: today) {
            //                return "오늘" // ✅ 오늘 날짜 밑에 "오늘" 표시
            //            }
            //            return nil
            
        
        
        
        //        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        //                    let calendar = Calendar.current
        //                    let weekday = calendar.component(.weekday, from: date) // 요일 가져오기 (1: 일요일, 7: 토요일)
        //
        //                    if weekday == 1 || weekday == 7 {
        //                        return .red  // ✅ 토요일(7)과 일요일(1)은 빨간색으로 표시
        //                    } else {
        //                        return .black // ✅ 평일은 검정색
        //                    }
        //                }
        
        // 날짜 선택 시 콜백 호출
        func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
            parent.selectedDate = date
            parent.dateSelectAction?(date) // 콜백 호출
        }
    }
}


#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date() // ✅ State 변수 추가
        
        var body: some View {
            CalendarSetView(selectedDate: $selectedDate) // ✅ Binding 전달
        }
    }
    
    return PreviewWrapper()
}
