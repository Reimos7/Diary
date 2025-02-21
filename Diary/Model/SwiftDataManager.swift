//
//  SwiftDataManager.swift
//  Diary
//
//  Created by Reimos on 2/20/25.
//
import Foundation
import SwiftUI
import SwiftData

@MainActor
class SwiftDataManager: ObservableObject {
    /*
     UIKit에서 사용할때랑 SwiftUI 차이
     SwiftUI.View는 기본적으로 MainActor에서 실행되지만, UIViewController는 MainActor와 관련 없이 실행됨 → mainContext에 접근해도 문제가 없음.
     SwiftData의 mainContext는 @MainActor 속성이 지정되어 있기 때문에 비동기적으로 실행되지 않으면 접근이 제한
     UIKit 기반의 UIViewController는 모든 UI 업데이트가 기본적으로 Main Thread에서 실행됨.
     따라서 mainContext는 자동으로 Main Thread에서 실행되므로 오류가 발생하지 않음.
     
     SwiftUI에서는 @MainActor를 추가해야 하지만, UIKit에서는 기본적으로 Main Thread에서 실행되기 때문에 오류가 발생하지 않는다!
     SwiftData의 mainContext는 @MainActor에서 실행되어야 하기 때문에, SwiftDataManager 전체를 @MainActor로 설정하면 자동으로 해결
     */
    var container: ModelContainer?
    
    var context: ModelContext? {
        return container?.mainContext
    }
    
    // 저장된 일기 목록 저장함
    @Published var diaryEntries: [Diary] = []
    
    init() {
        do {
            // SwiftData의 모델 컨테이너를 초기화
            container = try ModelContainer(for: Diary.self)
        } catch {
            fatalError("SwiftData 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // Create 새로운 일기 추가
    func addDiaryData(content: String, date: Date) {
        guard let context = context else {return}
        
        let diaryNewData = Diary(content: content, date: date)
        // 데이터 추가
        context.insert(diaryNewData)
        // 저장
        saveContext()
    }
    
    // Read 일기 목록 조회
    func fetchDiaryData() -> [Diary] {
        guard let context = context else {return []}
        
        do {
            // 최신 날짜 순으로 정렬
            let fetchDiary = FetchDescriptor<Diary>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            // 데이터 가져오기
            let results = try context.fetch(fetchDiary) //  데이터를 변수에 저장
            self.diaryEntries = results // @Published 변수 업데이트
            return results // 데이터를 반환
            
        } catch {
            print("데이터 가져오기 실패함 \(error.localizedDescription)")
            return []
        }
    }
    
    // Update (기존 일기 수정하기)
    func updateDiaryData(entry: Diary, newContent: String) {
        guard let context = context else {return}
        // 내용 업데이트
        entry.content = newContent
        saveContext()
    }
    
    // Delete (일기 삭제)
    func deleteDiaryData(entry: Diary) {
        guard let context = context else {return}
        // 데이터 삭제
        context.delete(entry)
        saveContext()
    }
    
    // SwiftData에서는 CordData처럼 Save를 안해줘도 되지만, 바로 저장하고 싶으니 함수로 만듬
    private func saveContext() {
        do {
            try context?.save() // 변경 사항 저장
        } catch {
            print("데이터 저장 실패 \(error.localizedDescription)")
        }
    }
}
