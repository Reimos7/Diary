//
//  SettingView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI

struct SettingView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    ThemeView()
                } label: {
                    Text("화면 테마")
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingView()
}
