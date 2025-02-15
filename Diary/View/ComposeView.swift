//
//  ComposeView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import SwiftUI

struct ComposeView: View {
    var body: some View {
        VStack {
            
            Image(systemName: DummyContainer.preview.weatherIcon)
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
            Text(DummyContainer.preview.date)
            Text(DummyContainer.preview.week)
            Spacer()
        }
    }
}

#Preview {
    ComposeView()
}
