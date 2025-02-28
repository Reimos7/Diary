//
//  SwiftUIView.swift
//  Diary
//
//  Created by Reimos on 2/21/25.
//

import SwiftUI
import SwiftData
// 작성한 일기 목록 전체를 보여주는 뷰
// 일기를 선택하면 -> DetailView로 들어가서 편집 및 삭제 기능 구현해야 됨
struct ListView: View {
    // true -> 내림차순(최근)
    @State private var sortByDateDesc: Bool = true
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        NavigationStack() {
            List {
                ForEach(manager.diaryEntries, id: \.self) { data in
                    // 일기를 선택하면 해당 일기 DetailView로 이동
                    NavigationLink {
                        DetailView(data: data)
                    } label: {
                        DiaryCell(diaryCellData: data)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .navigationTitle("일기 목록")
            // 화면이 나타날 때 데이터 로드
            .onAppear {
                manager.fetchDiaryData(isDecending: sortByDateDesc)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // 검색화면으로 이동
                    NavigationLink {
                        SearchView()
                    } label: {
                        Image("search_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24) // SF Symbol 크기와 유사하게 조정
                            .foregroundColor(.primary)
                    }
                    // 정렬 버튼
                    Button {
                        sortByDateDesc.toggle()
                        manager.fetchDiaryData(isDecending: sortByDateDesc)
                    } label: {
                        Image("reverseSearch_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30) // SF Symbol 크기와 유사하게 조정
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    // 스와이프 삭제 기능
    func delete(set: IndexSet) {
        for index in set {
            manager.deleteDiaryData(entry: manager.diaryEntries[index])
        }
    }
}

