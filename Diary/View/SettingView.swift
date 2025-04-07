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
                ZStack {
                    NavigationLink {
                        NotificationView()
                    } label: {
                        EmptyView()
                        
                    }.opacity(0)
                    HStack(spacing: 8) { // ← 간격을 적절히 조절 (원하는 만큼)
                        Image("notification2_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary)

                        Text("알림")

                        Spacer()
                    }
                    
                }
                .listRowSeparator(.hidden) // 줄 없애기
                
                ZStack {
                    NavigationLink {
                        ThemeView()
                    } label: {
                        EmptyView()
                        
                    }.opacity(0)
                    HStack(spacing: 8) {
                        Image("theme_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary)
                        
                        Text("테마")
                        
                        Spacer()
                        
                    }
                }
                .listRowSeparator(.hidden) // 줄 없애기
            }
            //.frame(maxWidth: .infinity, alignment: .leading)
            //.padding()
            .listStyle(.plain)
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
