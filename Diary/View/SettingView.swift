//
//  SettingView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI

struct SettingView: View {
    @Environment(\.dismiss) var dismiss
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
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // 뒤로 가기 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // 뒤로 가기 동작 (현재 뷰 닫기)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(uiColor: UIColor.label))
                    }
                    .tint(.clear) // 버튼에 기본 tint 색(파란색) 무력화
                }
            }
        }
    }
}

#Preview {
    SettingView()
}
