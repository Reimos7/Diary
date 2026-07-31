//
//  SearchView.swift
//  Diary
//
//  Created by Reimos on 2/23/25.
//

import SwiftUI
import SwiftData
// 검색 화면
struct SearchView: View {
    @State private var keyword: String = ""
    // 사용자가 textField에 입력 중인지 확인하는 변수
    @State private var isTyping: Bool = false
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    // FocusState 이용하여 자동으로 키보드 보여주기
    @FocusState var focused: Bool
    
    var body: some View {
        NavigationStack() {
            VStack {
                // 검색어가 존재하고 입력이 완료된 경우에만 리스트에 표시함
                if !keyword.isEmpty && !isTyping {
                    List {
                        ForEach(Array(manager.diaryEntries.enumerated()), id: \.element) { pair in
                            ZStack {
                                // 기록 화면과 동일한 셀 (좌우 번갈아 배치)
                                DiaryCell(data: pair.element, index: pair.offset)

                                NavigationLink(destination: DetailView(data: pair.element)) {
                                    EmptyView()
                                }
                                .buttonStyle(.plain)
                                .opacity(0)
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.md, bottom: 0, trailing: AppSpacing.md))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                } else {
                    Spacer()
                    Text("일기를 검색해주세요")
                        .customFont(size: 16)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .paperBackground()
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // 뒤로 가기 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .tint(.clear)
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        TextField("일기를 검색 해주세요", text: $keyword, onEditingChanged: { editing in
                            isTyping = editing
                        })
                        .customFont(size: 16)
                        .foregroundStyle(AppColor.textPrimary)
                        .padding(1)
                        .frame(maxWidth: .infinity)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($focused)
                    }
                    .padding(.horizontal, 5)
                    .frame(maxWidth: .infinity)
                }
                // 검색 버튼 - 키보드 엔터키와 동일한 액션
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        performSearch()
                    } label: {
                        Image("search_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                }
            }
            
            // 0.5초 뒤에 키보드 자동으로 올려주기
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.focused = true
                }

            }
            // Analytics: 검색 화면 진입 추적
            .trackScreen("Search")
            // 검색 기능 구현
            // prompt는 placeholder다
            // searchable은 서치바를 추가해주고 입력한 검색어를 바인딩해줌 나머지는 알아서 구현해아 함
            // .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "내용을 검색 합니다")
            
            // keyword가 바뀌면 클로저 실행
            // keyword 값이 바뀌면 자동으로 검색 실행
            .onChange(of: keyword) { _, keywordData in
                if keywordData.isEmpty {
                    // 검색어가 비어 있으면 리스트 비우기
                    manager.diaryEntries = []
                } else {
                    // 검색어가 있으면 해당 키워드를 포함한 데이터 검색
                    manager.searchDiaryData(keyword: keywordData)
                }
            }
        }
    }
    
    // 검색을 실행하는 함수
    private func performSearch() {
        if keyword.isEmpty {
            manager.diaryEntries = []
        } else {
            manager.searchDiaryData(keyword: keyword)
        }
        focused = false // 키보드 닫기
        isTyping = false // 검색 실행 후 입력 상태 종료
    }
    
}


// SwiftUI에서 UIKit의 UINavigationController를 감싸서 사용
struct NavigationControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            viewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    SearchView()
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
