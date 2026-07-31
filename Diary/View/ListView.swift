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
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    
    var body: some View {
        NavigationStack() {
            List {
                ForEach(Array(manager.diaryEntries.enumerated()), id: \.element) { pair in
                    ZStack {
                        // 실제로 보이는 셀 (좌우 번갈아 배치를 위해 순번 전달)
                        DiaryCell(data: pair.element, index: pair.offset)

                        // 터치 영역을 만들기 위한 투명 버튼 → 상세 이동
                        NavigationLink(destination: DetailView(data: pair.element)) {
                            EmptyView()
                        }
                        .buttonStyle(.plain)
                        .opacity(0)
                    }
                    .listRowSeparator(.hidden)      // 줄 없애기
                    .listRowBackground(Color.clear) // 행 배경 투명 (크림 배경 보이게)
                    .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.md, bottom: 0, trailing: AppSpacing.md))
                }
                .onDelete(perform: delete)

            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden) // 리스트 기본 배경 제거
            .paperBackground()                // 종이 질감 배경
            
            // 화면이 나타날 때 데이터 로드
            .onAppear {
                manager.fetchDiaryData(isDecending: sortByDateDesc)
                // Analytics: 일기 목록 화면 진입 추적. 광고 예정 위치이므로 체류/노출 근거로 사용.
                AnalyticsManager.log(.screenViewed(name: "List"))
            }
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            .toolbar {
                // 타이틀 직접 설정
                ToolbarItem(placement: .principal) {
                    Text("일기 기록")
                        .customFont(size: 20)
                        .foregroundStyle(AppColor.textPrimary)
                }
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
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
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
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                    }
                }
            }
        }
    }
    // 스와이프 삭제 기능
    func delete(set: IndexSet) {
        for index in set {
            // SwiftData(Context)에서 삭제
            manager.deleteDiaryData(entry: manager.diaryEntries[index])
            // 배열에서도 즉시 삭제
            manager.diaryEntries.remove(at: index)
            // 삭제 후 바로 SwiftData context 저장
            manager.saveContext()
        }
    }
}

