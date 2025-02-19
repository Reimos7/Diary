//
//  FSCalenderComposeView.swift
//  Diary
//
//  Created by Reimos on 2/19/25.
//

import SwiftUI

struct FSCalenderComposeView: View {
    let selectedDate: Date
        
        // 날짜 포맷터
        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                
            }
            .padding()
            .navigationTitle(dateFormatter.string(from: selectedDate))
        }
}

#Preview {
    FSCalenderComposeView(selectedDate: Date.now)
}
