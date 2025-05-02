//
//  FileManagerSet.swift
//  Diary
//
//  Created by Reimos on 3/4/25.
//

import Foundation
import SwiftUI

// 파일명 기반 저장 및 불러오기 방식 적용
struct FileManagerSet {
    
    // MARK: 이미지 저장 (파일명만 반환)
    static func saveImageToFileManager(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let fileName = UUID().uuidString + ".jpg" // [변경] 고유한 파일명 생성
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName // [리팩토링] 전체 경로 대신 파일명만 반환
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    // MARK: 이미지 삭제 (파일명 기반)
    static func deleteImageFromFileManager(fileName: String) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("이미지 삭제 성공: \(fileURL.path)")
            } catch {
                print("이미지 삭제 실패: \(error.localizedDescription)")
            }
        } else {
            print("파일이 존재하지 않음: \(fileURL.path)")
        }
    }
    
    // MARK: 이미지 불러오기 (파일명 기반)
    static func loadImageFromFileManager(fileName: String) -> UIImage? {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
}
