//
//  DateFormatter.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import Foundation

extension DateFormatter {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 EEEE" // 요일 포함
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "a hh:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}
