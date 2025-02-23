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
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        NavigationStack  {
            VStack {
                if keyword.isEmpty {
                    Spacer()
                    Text("일기를 검색해주세요")
                    Spacer()
                } else {
                    List {
                        ForEach(manager.diaryEntries, id: \.self) { data in
                            // 일기를 선택하면 해당 일기 DetailView로 이동
                            NavigationLink {
                                DetailView(data: data)
                            } label: {
                                DiaryCell(diaryCellData: data)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            // 검색 기능 구현
            // prompt는 placeholder다
            // searchable은 서치바를 추가해주고 입력한 검색어를 바인딩해줌 나머지는 알아서 구현해아 함
            .searchable(text: $keyword, placement: .navigationBarDrawer(displayMode: .always), prompt: "내용을 검색 합니다")
            // keyword가 바뀌면 클로저 실행
            // keyword 값이 바뀌면 자동으로 검색 실행
            .onChange(of: keyword) { keywordData in
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
  
}

#Preview {
    SearchView()
}
