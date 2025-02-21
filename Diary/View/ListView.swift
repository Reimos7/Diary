//
//  SwiftUIView.swift
//  Diary
//
//  Created by Reimos on 2/21/25.
//

import SwiftUI
// 작성한 일기 목록 전체를 보여주는 뷰
// 일기를 선택하면 -> DetailView로 들어가서 편집 및 삭제 기능 구현해야 됨
struct ListView: View {
    
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(manager.diaryEntries, id: \.self) { data in
                    // 일기를 선택하면 해당 일기 DetailView로 이동
                    NavigationLink {
                        DetailView()
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
                manager.fetchDiaryData()
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

#Preview {
    ListView()
}
