//
//  LaunchScreenView.swift
//  Diary
//
//  Created by Reimos on 4/22/25.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        Image("LaunchImage")
            .resizable()
            .frame(width: 150, height: 150)
        Text("GoodD")
            .font(.custom("dovemayo", size: 26))
    }
}

#Preview {
    LaunchScreenView()
}
