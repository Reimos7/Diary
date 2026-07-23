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

    // LanguageView에서 언어가 바뀌면 이 값도 자동 업데이트되어 우측 텍스트가 즉시 반영
    // 기본값: 시스템 언어가 지원 목록에 있으면 그 언어, 없으면 영어
    @AppStorage("appLanguage") private var appLanguage: String = resolvedSystemLanguage()
    
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

                // 언어 설정 - LanguageView로 이동 
                ZStack {
                    NavigationLink {
                        LanguageView()
                    } label: {
                        EmptyView()
                    }.opacity(0)
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.primary)

                        Text("언어")

                        Spacer()

                        // 현재 설정된 언어 표시
                        Text(currentLanguageDisplayName())
                            .foregroundStyle(.secondary)
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
                
                ZStack {
                    Button {
                        // 앱스토어 리뷰 화면 이동
                        let urlString = "https://apps.apple.com/app/id\(AppID.diaryAppID)?action=write-review"
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        EmptyView()
                        
                    }.opacity(0)
                    HStack(spacing: 8) {
                        Image("store_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary)
                        
                        Text("앱 평가하기")
                        
                        Spacer()
                        
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
                        
                        Text("1.3.0")
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
        // Analytics: 설정 화면 진입 추적
        .trackScreen("Setting")
    }

    // 현재 앱에 설정된 언어를 사용자에게 보여줄 이름으로 변환
    private func currentLanguageDisplayName() -> String {
        switch appLanguage {
        case "ko": return "한국어"
        case "en": return "English"
        case "ja": return "日本語"
        default: return appLanguage
        }
    }
}
