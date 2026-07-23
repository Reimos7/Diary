//
//  LanguageView.swift
//  Diary
//
//  Created by Reimos on 3/1/26.
//

import SwiftUI
import WidgetKit

struct LanguageView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: WeatherService

    // DiaryApp.swift의 @AppStorage("appLanguage")와 동일한 키를 공유
    // 이 값을 바꾸면 DiaryApp의 .environment(\.locale)이 자동으로 반응하여
    // 앱 전체 UI가 즉시 새 언어로 다시 렌더링됨 (재시작 불필요)
    // 기본값: 시스템 언어가 지원 목록에 있으면 그 언어, 없으면 영어
    @AppStorage("appLanguage") private var appLanguage: String = resolvedSystemLanguage()

    // 지원하는 언어 목록 (코드, 표시 이름, 예시 문장)
    // 표시 이름은 각 언어의 원어로 고정 (번역하면 혼동될 수 있음)
    private let languages: [(code: String, name: String, sample: String)] = [
        ("ko", "한국어", "매일 매일이 행복한 하루가 되길 바랄게"),
        ("en", "English", "I hope every day is a happy day for you"),
        ("ja", "日本語", "毎日毎日が幸せな一日になりますように")
    ]

    var body: some View {
        // FontView와 동일한 구조: 상단 미리보기 + 하단 리스트
        ZStack {
            // 위치 권한이 거부된 상태라면
            if service.showLocationDeniedWeatherView {
                Text("위치 권한을 허용하면 날씨를 기록할 수 있어요!\n")
            } else {
                if let model = service.currentWeather {
                    Image(systemName: model.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 100, maxHeight: 100)
                        .offset(x: 1, y: 1)
                        .foregroundStyle(.gray.opacity(0.3))

                    Image(systemName: model.icon)
                        .symbolRenderingMode(.multicolor)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 100, maxHeight: 100)
                }
            }
        }
        .shadow(radius: 2)

        Text(DateFormatter.dateFormatter.string(from: Date.now))
            .padding()
            .foregroundStyle(.secondary)
            .customFont(size: 16)

        // 현재 선택된 언어의 예시 문장을 보여줌
        Text(languages.first(where: { $0.code == appLanguage })?.sample
             ?? languages[0].sample)
            .padding()

        Divider()

        // 언어 목록 리스트
        List {
            ForEach(languages, id: \.code) { language in
                Button {
                    // @AppStorage에 언어 코드 저장
                    // UserDefaults.standard에 즉시 반영됨
                    // DiaryApp의 .environment(\.locale)이 자동 반응하여 UI 갱신
                    appLanguage = language.code

                    // Analytics: 언어 변경(기능 인기도 계측)
                    AnalyticsManager.log(.languageChanged(language: language.code))

                    // 위젯에도 언어 설정 공유
                    // 위젯은 별도 프로세스이므로 App Group UserDefaults를 통해 공유
                    let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
                    sharedDefaults?.set(language.code, forKey: "appLanguage")

                    // 위젯 갱신 요청
                    WidgetCenter.shared.reloadAllTimelines()

                    // 날씨 데이터를 새 언어로 다시 가져오기 (위치 주소도 새 언어로 변환)
                    service.updateWeatherManually()
                } label: {
                    HStack {
                        // 언어 이름 (한국어, English, 日本語)
                        Text(language.name)

                        Spacer()

                        // 현재 선택된 언어에 체크 표시 (FontView와 동일한 스타일)
                        Image(systemName: appLanguage == language.code ? "circle.circle.fill" : "circle")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        // 기본 뒤로 가기 버튼 숨김
        .navigationBarBackButtonHidden()
        // 스와이프 뒤로 가기 활성화
        .background(NavigationControllerWrapper())

        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("언어 설정")
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(uiColor: UIColor.label))
                }
                .tint(.clear)
            }
        }
    }
}
