//
//  CaptureManager.swift
//  Diary
//
//  Created by Reimos on 3/9/25.
//


// 1 단계: 스크린 샷을 찍고 앨범에 저장
// 2 단계: 스크린 샷을 찍고 공유를 통해 바로 캡쳐본을 전달하기
import SwiftUI
import Photos

// UIView 확장을 통해 해당 뷰를 UIImage로 변환 하는 함수 구현
// changeUIImage - 현재 UIView를 UIImage로 변환하는 함수
extension UIView {
    func changeUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
// saveCaptureImageToAlbum - 주어진 스크린샷 이미지를 앨범에 저장
// UIImageWriteToSavedPhotosAlbum - 스크린샷 이미지를 앨범에 저장한후 print 실행
func saveCaptureImageToAlbum(_ screenshot: UIImage) {
    UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
    print("스크린샷 저장 성공!!!")
}

