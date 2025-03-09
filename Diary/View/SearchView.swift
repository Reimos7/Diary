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
                        ForEach(manager.diaryEntries, id: \.self) { data in
                            
                            ZStack {
                                // 디자인을 위해 보여지는 셀
                                DiaryCell(diaryCellData: data)
                                
                                // 터치 영역을 위한 투명 버튼
                                NavigationLink(destination: DetailView(data: data)) {
                                    EmptyView()
                                }
                                // 네비게이션 링크 표시 제거
                                .buttonStyle(.plain)
                                // 터치 영역 유지 (보이지 않게 설정)
                                .opacity(0)
                            }
                            // 줄 없애기
                            .listRowSeparator(.hidden)
                        }
                    }
                    // 리스트 배경 제거
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    
                } else {
                    Spacer()
                    Text("일기를 검색해주세요")
                    Spacer()
                }
            }
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
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        TextField("일기를 검색 해주세요", text: $keyword, onEditingChanged: { editing in
                            // 입력 중이면 true, 입력이 끝나면 false
                            isTyping = editing
                        })
                        .font(.system(size: 16))
                        .padding(1)
                        .frame(maxWidth: .infinity)
                        .textFieldStyle(PlainTextFieldStyle())
                        //.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .focused($focused)
                        
                    }
                    .padding(.horizontal,5)
                    .frame(maxWidth: .infinity)
                    //.background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    //.padding(.horizontal, 8)
                    //                    .overlay {
                    //                        RoundedRectangle(cornerRadius: 5)
                    //                            .stroke(Color.gray, lineWidth: 0.5)
                    //
                    //                    }
                }
                // 검색 버튼 - 키보드 엔터키와 동일한 액션
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        performSearch()
                    } label: {
                        Image("search_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24) // SF Symbol 크기와 유사하게 조정
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // 0.5초 뒤에 키보드 자동으로 올려주기
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.focused = true
                }
                
            }
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
}
