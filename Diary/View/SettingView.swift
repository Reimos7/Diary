//
//  SettingView.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import SwiftUI

struct SettingView: View {
    // 이메일
    private var email = EmailManager(toAddress: EmailAddress.developerEmail, subject: "굿디 문의하기")
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        NavigationStack {
            List {
                ZStack {
                    NavigationLink {
                        NotificationView()
                    } label: {
                        EmptyView()
                        
                    }.opacity(0)
                    HStack(spacing: 8) {
                        Image("notification_img")
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
                
                ZStack {
                    NavigationLink {
                        FontView()
                    } label: {
                        EmptyView()
                        
                    }.opacity(0)
                    HStack(spacing: 8) {
                        Image("font_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary)
                        
                        Text("폰트")
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden) // 줄 없애기
                
                Divider()
                
                ZStack {
                    Button {
                        email.send(openURL: openURL)
                    } label: {
                        HStack(spacing: 8) {
                            Image("email_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary)
                            
                            Text("문의하기")
                            
                            Spacer()
                            
                        }
                    }
                }
                .listRowSeparator(.hidden) // 줄 없애기
                
                Divider()
                
                ZStack {
                    HStack(spacing: 8) {
                        Image("appVersion_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary)
                        
                        Text("앱 버전")
                        
                        Spacer()
                        
                        Text("1.0.0")
                    }
                }
                .listRowSeparator(.hidden) // 줄 없애기
            }
            .listStyle(.plain)
            //.navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // navigationTitle 대신 커스텀 폰트 적용을 위해 구현
                ToolbarItem(placement: .principal) {
                    Text("설정")
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
        // 설정화면 통해 알림 권한 요청 alert
        .onAppear {
            NotificationManager.shared.requestAutorization()
        }
    }
}
