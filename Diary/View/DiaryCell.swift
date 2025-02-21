//
//  DiaryCell.swift
//  Diary
//
//  Created by Reimos on 2/21/25.
//

import SwiftUI
// ListView에서 보여주는 Diary Cell
struct DiaryCell: View {
    
    let diaryCellData: Diary
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Aisa/Seoul")
        return formatter
    }
    
    var body: some View {
        VStack {
            Text(diaryCellData.content)
                .lineLimit(1)
            Text(dateFormatter.string(from: diaryCellData.date))
            
        }
    }
}

