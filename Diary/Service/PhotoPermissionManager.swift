//
//  PhotoPermissionManager.swift
//  Diary
//
//  Created by Reimos on 4/20/25.
//

import UIKit
import Photos

// 사진 권한 요청 및 상태 확인 파일
struct PhotoPermissionManager {
    
    // 현재 권한 상태 확인 후 아직 결정되지 않았으면 사용자에게 권한 요청
    // Parameter completion: 권한 요청 결과를 전달하는 클로저 (메인 스레드에서 실행됨)
    static func checkPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch currentStatus {
            // 아직 권한을 요청한 적이 없다면 사용자에게 권한 요청하기
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    // 새로운 상태 콜백 반환
                    completion(newStatus)
                }
            }
            // 이미 권한이 존재 한다면 상태 그대로 반환
        default:
            completion(currentStatus)
        }
    }
    
    // 권한이 거부된 상태라면 설정 앱을 열어 사용자에게 권한 변경 유도
    static func openPhotoSetting() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // 사용자 권한 설명 메시지
    static func photoPermissionMessage(for status: PHAuthorizationStatus) -> String {
        switch status {
        case  .denied, .restricted:
            return "일기 사진 첨부를 위해 접근 권한이 필요합니다."
        case .limited:
            return "사진 일부만 접근 가능합니다. 전체 권한을 허용하려면 설정을 확인해 주세요."
        case .authorized:
            return "사진 접근이 허용되었습니다."
        case .notDetermined:
            return "사진 접근 권한이 아직 요청되지 않았습니다."
        @unknown default:
            return "알 수 없는 권한 상태입니다."
        }
    }
}
