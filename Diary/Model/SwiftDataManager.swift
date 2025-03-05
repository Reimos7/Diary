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
    var imagePath: String? = nil
    // 선택된 이미지 저장
    @State private var selectedImages: [UIImage] = []
    
    // 저장된 일기 목록 저장함
    @Published var diaryEntries: [Diary] = []
    
    init() {
        do {
            // SwiftData의 모델 컨테이너를 초기화
            container = try ModelContainer(for: Diary.self)
            // 실행시 바로 데이터 불러오기
            fetchDiaryData(isDecending: true)
        } catch {
            fatalError("SwiftData 초기화 실패: \(error.localizedDescription)")
        }
    }
    
    // Create 새로운 일기 추가 - 이미지 추가 가능
    func addDiaryData(content: String, date: Date, imagePath: [String]? = nil) {
        guard let context = context else {return}
        
        let diaryNewData = Diary(content: content, date: date, imagePath: imagePath)
        // 데이터 추가
        context.insert(diaryNewData)
        // 저장
        saveContext()
        print("저장 완료됨>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    }
    
    // Read 일기 목록 조회 , 파라미터로 오름차순, 내림차순 결정
    func fetchDiaryData(isDecending: Bool) -> [Diary] {
        guard let context = context else {return []}
        
        do {
            let sortOrder: SortOrder = isDecending ? .reverse : .forward
            // 최신 날짜 순으로 정렬
            let fetchDiary = FetchDescriptor<Diary>(sortBy: [SortDescriptor(\.date, order: sortOrder)])
            // 데이터 가져오기
            let results = try context.fetch(fetchDiary) //  데이터를 변수에 저장
            self.diaryEntries = results // @Published 변수 업데이트
            return results // 데이터를 반환
            
        } catch {
            print("데이터 가져오기 실패함 \(error.localizedDescription)")
            return []
        }
    }
    // 특정 날짜에 저장된 일기가 존재하는지 확인
    func hasDiaryentry(for date: Date) -> Bool {
        return diaryEntries.contains { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: date)
            
        }
    }
    
    // 검색을 통한 일기 목록 조회하기
    func searchDiaryData(keyword: String) {
        guard let context = context else {return}
        
        do {
            // Diary 모델의 content에서 keyword가 포함된 데이터를 찾도록 설정
            let predicate = #Predicate<Diary> { $0.content.contains(keyword)}
            
            // 검색 조건을 적용해서 데이터를 최신순으로 정렬
            let fetchDescriptor = FetchDescriptor<Diary>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            // 검색 결과를 diaryEntries에 저장하여 화면을 업데이트
            self.diaryEntries = try context.fetch(fetchDescriptor)
        } catch {
            print("검색 실패: \(error.localizedDescription)")
        }
    }
    
    // Update (기존 일기 수정하기)
    func updateDiaryData(entry: Diary, newContent: String) {
        guard let context = context else {return}
        // 내용 업데이트
        entry.content = newContent
        saveContext()
    }
    
    // Delete (일기 삭제) - 저장된 이미지 경로도 삭제 
    func deleteDiaryData(entry: Diary) {
        guard let context = context else {return}
        // 저장된 이미지 경로 존재 시 삭제
        if let paths = entry.imagePath {
            for path in paths {
                FileManagerSet.deleteImageFromFileManager(at: path)
            }
        }
        
        // 데이터 삭제
        context.delete(entry)
        saveContext()
    }
    
    // SwiftData에서는 CordData처럼 Save를 안해줘도 되지만, 바로 저장하고 싶으니 함수로 만듬
     func saveContext() {
        do {
            try context?.save() // 변경 사항 저장
        } catch {
            print("데이터 저장 실패 \(error.localizedDescription)")
        }
    }
}
