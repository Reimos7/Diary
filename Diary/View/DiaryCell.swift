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
 
    var body: some View {
        VStack {
            Text(diaryCellData.content)
                .lineLimit(1)
            Text(DateFormatter.dateFormatter.string(from: diaryCellData.date))
            
        }
    }
}

