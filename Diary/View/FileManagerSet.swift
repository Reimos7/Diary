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

    static func loadImageFromFileManager(path: String) -> UIImage? {
        guard let url = URL(string: path) else { return nil }
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}
