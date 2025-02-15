//
//  ContentView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI
import SwiftData
import FSCalendar

struct MainView: View {
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                // 캘린더
                FSCalendarView(selectedDate: $selectedDate)
                    .frame(width: 400, height: 400)
                NavigationLink {
                    ComposeView()
                }           label: {
                    Image(systemName: "pencil")
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    
                }
            }
        }
        
        
    }
}
#Preview {
    MainView()
    
}

