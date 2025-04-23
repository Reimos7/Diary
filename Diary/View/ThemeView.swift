//
//  ThemeView.swift
//  Diary
//
//  Created by Reimos on 3/18/25.
//

import SwiftUI

struct ThemeView: View {
    // 저장된 테마 상태
    @AppStorage("selectedTheme") private var selectedTheme: ThemeOption = .system
    // 현재 다크/라이트 모드 감지
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectTheme(.system)
                } label: {
                    HStack {
                        Text("시스템 설정")
                        Spacer()
                        Image(systemName: selectedTheme == .system ? "circle.circle.fill" : "circle")
                            .foregroundStyle(.gray)
                    }
                }
                .listRowSeparator(.hidden)
                
                Button {
                    selectTheme(.light)
                } label: {
                    HStack {
                        Text("라이트 모드")
                        Spacer()
                        Image(systemName: selectedTheme == .light ? "circle.circle.fill" : "circle")
                            .foregroundStyle(.gray)
                    }
                }
                .listRowSeparator(.hidden)
                
                Button {
                    selectTheme(.dark)
                } label: {
                    HStack {
                        Text("다크 모드")
                        Spacer()
                        Image(systemName: selectedTheme == .dark ? "circle.circle.fill" : "circle")
                            .foregroundStyle(.gray)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            //.navigationTitle("테마 설정")
            .navigationBarTitleDisplayMode(.inline)
            // 시스템 모드 감지 후 반영
            .preferredColorScheme(getColorScheme())
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // navigationTitle 대신 커스텀 폰트 적용을 위해 구현
                ToolbarItem(placement: .principal) {
                    Text("테마 설정")
                }
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
    
    // 테마 변경 함수 (하나만 선택되도록)
    private func selectTheme(_ theme: ThemeOption) {
        selectedTheme = theme  // 선택된 테마 저장
    }
    
    // 현재 설정된 ColorScheme을 반환 (시스템 모드 선택 시 자동 반영)
    private func getColorScheme() -> ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil  // 시스템 설정 그대로 유지
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// 선택 가능한 테마 Enum (UserDefaults 저장 가능하도록 `String` 타입 지정)
enum ThemeOption: String, CaseIterable {
    case system, light, dark
}

#Preview {
    ThemeView()
}
