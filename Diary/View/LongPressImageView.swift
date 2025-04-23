//
//  LongPressImageView.swift
//  Diary
//
//  Created by Reimos on 4/10/25.
//

import SwiftUI

// CalendarComposeView, ComposeView에서 이미지를 길게 눌렀을때 휴지통 버튼을 통해 이미지를 뷰에서 삭제
// EditComposeView에서는 이미지를 길게 눌렀을때 휴지통 버튼을 통해 이미지를 뷰에서 삭제하고, 실제 Diary의 SwiftData에서 이미지 파일 삭제
struct LongPressImageView: View {
    
    var image: UIImage
    var imagePath: String? // 이미지 경로 추가
    @Binding var isLongPressedPhoto: Bool
    @Binding var selectedImages: [UIImage]
    @Binding var selectedImageForFullscreen: IdentifiableImage?
    
    // EditComposeView에서 실제 Diary 이미지 데이터 삭제를 위해 선언
    @EnvironmentObject var manager: SwiftDataManager
    
    var diaryData: Diary?
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                // longPress로 이미지 자체 색상을 변경
                .colorMultiply(isLongPressedPhoto ? .gray : .white)
                .onTapGesture {
                    selectedImageForFullscreen = IdentifiableImage(image: image)
                }
                .onLongPressGesture {
                    isLongPressedPhoto.toggle()
                }
            
            // 이미지를 길게 누르면 쓰레기통이 나타남, 쓰레기통 버튼을 클릭하면 배열(selectedImages)에서 현재 이미지를 찾아서 제거함 (이미지가 현재 1개니까 일단 처음것만 제거하는 로직)
            if isLongPressedPhoto {
                Button {
                    // CalendarComposeView와 ComposeView에서만 적용
                    // image와 완전히 같은 이미지가 처음으로 등장하는 위치(index) 를 찾아서 제거
                    // 저장 하기 전에 단순 이미지만 지움
                    if let index = selectedImages.firstIndex(of: image) {
                        selectedImages.remove(at: index)
                    }
                    
                    // EditComposeView에서 버튼을 눌러 삭제하면 swiftData에서도 즉시 삭제 됨
                    // 편집이니까 실제 경로 지우기 (이미지 삭제)
                    if let path = imagePath {
                        // 경로에 맞는 이미지 파일 삭제
                        FileManagerSet.deleteImageFromFileManager(at: path)
                        
                        // SwiftData에서 이미지 경로 및 파일 삭제 (EditComposeView에서만)
                        if let diary = diaryData, var paths = diary.imagePath {
                            // 전체 경로 배열에서 해당 이미지 하나만 제거 즉, 삭제하고자 하는 파일의 경로만 필터링해서 제거
                            paths.removeAll() {$0 == path}
                            // paths가 비어있으면 nil로 설정, 아니면 업데이트 된 경로 배열 설정
                            diary.imagePath = paths.isEmpty ? nil : paths
                            // 삭제하고 즉시 SwiftData에 저장
                            manager.saveContext()
                        }
                    }
                }
                label: {
                    Image("trash_img")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                        .background(Color(.systemGray5))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.primary) // 다크모드에서도 자동 변경
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
