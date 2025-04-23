//
//  FileManagerSet.swift
//  Diary
//
//  Created by Reimos on 3/4/25.
//

import Foundation
import SwiftUI
// 파일 매니저 
struct FileManagerSet {
    static func saveImageToFileManager(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let fileName = UUID().uuidString + ".jpg" // 랜덤한 파일명
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)   // 파일 저장
            return fileURL.absoluteString // 경로를 String으로 반환
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    // 파일 삭제 함수 - 저장된 이미지 경로 삭제를 위한 함수
    // 파일이 실제로 존재 할때만 삭제함
    static func deleteImageFromFileManager(at path: String) {
        guard let fileURL = URL(string: path) else {
            print("잘못된 경로: \(path)")
            return
        }
        
        let filePath = fileURL.path // 실제 파일 경로 변환
        
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
                print("이미지 삭제 성공: \(filePath)")
            } catch {
                print("이미지 삭제 실패: \(error.localizedDescription)")
            }
        } else {
            print("파일이 존재하지 않음: \(filePath)")
        }
    }
    
    static func loadImageFromFileManager(path: String) -> UIImage? {
        guard let url = URL(string: path) else { return nil }
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}
