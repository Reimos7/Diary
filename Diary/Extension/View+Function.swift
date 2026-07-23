//
//  View+Function.swift
//  Diary
//
//  Created by Reimos on 3/20/25.
//

import SwiftUI

// 1. CustomKeyboardToolbarModifier를 수정하여 FocusState.Binding을 받도록 함
struct CustomKeyboardToolbarModifier: ViewModifier {
    // @FocusState 자체는 바인딩이 아니므로, 이 값을 다른 뷰에서 제어할 수 있도록 하기 위해 Binding<Bool>을 사용
    // @FocusState는 FocusState<Bool>을 관리하는데, 실제로 뷰에서 사용할 때는 Binding을 전달해야 하므로 FocusState<Bool>.Binding으로 설정
    var focused: FocusState<Bool>.Binding
    @Binding var content: String
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                // @FocusState는 FocusState<Bool> 타입을 관리하는데, 실제로 이 값을 바인딩하려면 wrappedValue를 사용
                // 포커스가 true일 때만 툴바가 화면에 보임 즉, 텍스트 편집 필드가 포커스될 때만 툴바가 활성화
                if focused.wrappedValue {
                    VStack(spacing: 0) {
                        // 상단 구분선
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(height: 0.5)
                        
                        // 툴바 아이콘
                        HStack {
                            Button {
                                self.content += DateFormatter.timeFormatter.string(from: Date())
                            } label: {
                                Image("clock_img")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundStyle(Color.primary)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button {
                                focused.wrappedValue = false
                            } label: {
                                Image("keyboard_img")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(Color.primary)
                                    .padding(8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 44)
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 0.25), value: focused.wrappedValue)
                }
            }
    }
}

// 2. View 확장을 수정하여 FocusState.Binding을 받음
extension View {
    func customKeyboardToolbar(focused: FocusState<Bool>.Binding, content: Binding<String>) -> some View {
        modifier(CustomKeyboardToolbarModifier(focused: focused, content: content))
    }
}

// 키보드 내리기
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 화면 진입 추적
// 사용법: 어떤 View의 body 맨 바깥에 .trackScreen("Main") 처럼 한 줄만 붙이면
// 해당 화면이 표시될 때마다 Firebase Analytics에 screen_view 이벤트가 전송된다.
// (화면마다 onAppear + logEvent를 직접 쓰는 중복을 없애기 위한 헬퍼)
extension View {
    func trackScreen(_ name: String) -> some View {
        onAppear {
            AnalyticsManager.log(.screenViewed(name: name))
        }
    }
}



