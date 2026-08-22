//
//  FileManagerSet.swift
//  Diary
//
//  Created by Reimos on 3/4/25.
//  사진을 App Group 컨테이너에 저장해 위젯과 공유한다.
//  (위젯은 별도 프로세스라 앱 샌드박스 Documents에 접근할 수 없으므로 App Group 필요)
//

import Foundation
import SwiftUI

// 파일명 기반 저장 및 불러오기 방식 적용
struct FileManagerSet {

    // MARK: - 저장 위치

    /// 위젯과 공유하는 App Group 컨테이너. (없으면 nil → Documents로 폴백)
    private static var appGroupDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedModelContainer.appGroupIdentifier)
    }

    /// 기존(구버전) 저장 위치. 마이그레이션 폴백용.
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// 신규 저장 기본 위치: App Group. App Group을 못 얻으면 Documents.
    private static var primaryDirectory: URL {
        appGroupDirectory ?? documentsDirectory
    }

    // MARK: - 이미지 저장 (파일명만 반환)
    static func saveImageToFileManager(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let fileName = UUID().uuidString + ".jpg"
        let fileURL = primaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }

    // MARK: - 이미지 삭제 (양쪽 위치 모두 정리)
    static func deleteImageFromFileManager(fileName: String) {
        var urls = [primaryDirectory.appendingPathComponent(fileName)]
        // App Group과 Documents가 다르면 구버전 위치도 함께 삭제
        let legacyURL = documentsDirectory.appendingPathComponent(fileName)
        if legacyURL != urls[0] { urls.append(legacyURL) }

        for url in urls where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - 이미지 불러오기 (App Group 우선, 없으면 구버전 Documents 폴백)
    static func loadImageFromFileManager(fileName: String) -> UIImage? {
        let candidates = [
            appGroupDirectory?.appendingPathComponent(fileName),
            documentsDirectory.appendingPathComponent(fileName)
        ].compactMap { $0 }

        for url in candidates {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return image
            }
        }
        return nil
    }

    // MARK: - 기존 사진 마이그레이션 (Documents → App Group, 최초 1회)
    /// 원본을 "복사"만 하므로(원본 유지) 실패해도 기존 사진은 안전하다.
    /// 로드는 App Group 우선 + Documents 폴백이라 마이그레이션이 부분 실패해도 사진이 안 사라진다.
    static func migratePhotosToAppGroupIfNeeded() {
        let flagKey = "photosMigratedToAppGroup"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        guard let appGroupDir = appGroupDirectory else { return } // App Group 없으면 다음 기회에

        let fm = FileManager.default
        do {
            let files = try fm.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for src in files where src.pathExtension.lowercased() == "jpg" {
                let dest = appGroupDir.appendingPathComponent(src.lastPathComponent)
                if !fm.fileExists(atPath: dest.path) {
                    try? fm.copyItem(at: src, to: dest)
                }
            }
            UserDefaults.standard.set(true, forKey: flagKey)
        } catch {
            print("사진 마이그레이션 실패: \(error)")
        }
    }
}
