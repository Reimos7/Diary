//
//  LaunchScreenView.swift
//  Diary
//
//  Created by Reimos on 4/22/25.
//  새 디자인: 크림 배경(앱 배경색과 동일) + AppIconV2 로고.
//

import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // 앱 배경색(크림)과 동일하게
            AppColor.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                // 투명 배경 로고 (흰 사각형 없이 해·구름만 크림 배경 위에)
                Image("AppLogoTransparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)

                Text("GoodDi")
                    .font(.custom("dovemayo", size: 30))
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
