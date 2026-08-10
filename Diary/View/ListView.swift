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

    // 네이티브 광고 삽입 간격(일기 N개마다 광고 1장).
    // 사용량 적은 앱은 "첫 광고가 빨리 나오는 것"이 노출/수익에 중요 → 3으로 설정.
    // (글 3개만 있어도 광고 1회 노출 보장, 정책상 1:3 밀도도 안전)
    private let adInterval = 3

    // 리스트의 한 행: 일기 셀 또는 광고.
    private enum FeedRow: Identifiable {
        case diary(offset: Int, entry: Diary)
        case ad(slot: Int)

        var id: String {
            switch self {
            case let .diary(_, entry): return "diary-\(ObjectIdentifier(entry))"
            case let .ad(slot): return "ad-\(slot)"
            }
        }
    }

    // 일기 목록에 adInterval 간격으로 광고 행을 끼운 최종 행 배열.
    private var feedRows: [FeedRow] {
        var rows: [FeedRow] = []
        var adSlot = 0
        for (offset, entry) in manager.diaryEntries.enumerated() {
            rows.append(.diary(offset: offset, entry: entry))
            if (offset + 1) % adInterval == 0 {
                rows.append(.ad(slot: adSlot))
                adSlot += 1
            }
        }
        return rows
    }
    
    var body: some View {
        NavigationStack() {
            List {
                // 일기 셀과 광고를 하나의 행 모델(FeedRow)로 합쳐 단일 ForEach로 그린다.
                // (한 요소가 여러 뷰를 반환하는 방식은 onDelete와 충돌해 광고 행이 안 그려질 수 있어 이렇게 분리)
                ForEach(feedRows) { row in
                    switch row {
                    case let .diary(offset, entry):
                        ZStack {
                            // 실제로 보이는 셀 (좌우 번갈아 배치를 위해 순번 전달)
                            DiaryCell(data: entry, index: offset)

                            // 터치 영역을 만들기 위한 투명 버튼 → 상세 이동
                            NavigationLink(destination: DetailView(data: entry)) {
                                EmptyView()
                            }
                            .buttonStyle(.plain)
                            .opacity(0)
                        }
                        .listRowSeparator(.hidden)      // 줄 없애기
                        .listRowBackground(Color.clear) // 행 배경 투명 (크림 배경 보이게)
                        .listRowInsets(EdgeInsets(top: 0, leading: AppSpacing.md, bottom: 0, trailing: AppSpacing.md))

                    case .ad:
                        // 네이티브 광고 행. 삭제 스와이프는 비활성화(일기만 삭제 가능).
                        NativeAdCard()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: AppSpacing.sm, leading: AppSpacing.md,
                                                      bottom: AppSpacing.sm, trailing: AppSpacing.md))
                            .deleteDisabled(true)
                    }
                }
                .onDelete(perform: deleteRows)

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
    // IndexSet은 feedRows(일기+광고 혼합) 기준이므로, 일기 행만 골라 실제 일기를 삭제한다.
    func deleteRows(_ offsets: IndexSet) {
        let rows = feedRows
        let entriesToDelete: [Diary] = offsets.compactMap { idx in
            if case let .diary(_, entry) = rows[idx] { return entry }
            return nil
        }
        for entry in entriesToDelete {
            // SwiftData(Context)에서 삭제
            manager.deleteDiaryData(entry: entry)
            // 배열에서도 즉시 삭제 (Diary는 클래스이므로 === 로 식별)
            if let i = manager.diaryEntries.firstIndex(where: { $0 === entry }) {
                manager.diaryEntries.remove(at: i)
            }
            // 삭제 후 바로 SwiftData context 저장
            manager.saveContext()
        }
    }
}

