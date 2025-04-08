//
//  PhotoPickerView.swift
//  Diary
//
//  Created by Reimos on 3/2/25.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView<Content: View>: View {
    // PhotoPicker와 상호 연동할 수 있는 선택된 Item 배열 상태 프로퍼티
    @Binding private var selectedPhotos: [PhotosPickerItem]
    // 실제 해당 컴포넌트를 호출한 상위 뷰와 바인딩 시킬 이미지 배열 프로퍼티
    @Binding var selectedImages: [UIImage]
    // 로드 중 실패 시 상위 뷰에 에러를 띄워주기 위해 감지하는 바인딩 프로퍼티
    @Binding var isPresentedError: Bool
    
    // Item을 선택할 수 있는 최대 개수
    private let maxSelectedCount: Int
    // 최대 개수가 선택된 경우 비활성화
    private var disabled: Bool {
        selectedImages.count >= maxSelectedCount
    }
    // 남은 선택 가능 개수
    private var availableSelectedCount: Int {
        maxSelectedCount - selectedImages.count
    }
    // 필터 타입 변수
    private let matching: PHPickerFilter
    // PHPhotoLibrary 타입의 인스턴스 변수
    private let photoLibrary: PHPhotoLibrary
    // 제네릭하게 받아온 View
    private let content: () -> Content
    
    init(
        selectedPhotos: Binding<[PhotosPickerItem]>,
        selectedImages: Binding<[UIImage]>,
        isPresentedError: Binding<Bool> = .constant(false),
        maxSelectedCount: Int = 1,
        matching: PHPickerFilter = .images,
        photoLibrary: PHPhotoLibrary = .shared(),
        content: @escaping () -> Content
    ) {
        self._selectedPhotos = selectedPhotos
        self._selectedImages = selectedImages
        self._isPresentedError = isPresentedError
        self.maxSelectedCount = maxSelectedCount
        self.matching = matching
        self.photoLibrary = photoLibrary
        self.content = content
    }

    var body: some View {
        PhotosPicker(
            selection: $selectedPhotos,
            maxSelectionCount: availableSelectedCount,
            matching: matching,
            photoLibrary: photoLibrary
        ) {
            content()
                .disabled(disabled)
        }
        // 현재 선택한 이미지 갯수가 최대 상한 갯수에 도달했을때 뷰와 기능을 비활성화
        .disabled(disabled)
        // 에셋에서 선택한 아이템의 변화가 있으면 내부 로직인 handleSelectedPhotos 메서드를 실행
        .onChange(of: selectedPhotos) { _ , newValue in
            handleSelectedPhotos(newValue)
        }
    }
    
    private func handleSelectedPhotos(_ newPhotos: [PhotosPickerItem]) {
        for newPhoto in newPhotos {
            // loadTransferable - 선택된 에셋에 대해 로드하고 진행상황을 추적
            newPhoto.loadTransferable(type: Data.self) { result in
                switch result {
            //성공 시 해당 이미지가 아직 selectedImages에 없는, 즉 기존에 없던 이미지라면 추가해주고 아니라면 추가해주지 않습니다
                case .success(let data):
                    if let data = data, let newImage = UIImage(data: data) {
            // pngData로 체크하는 이유는 그냥 Data를 가지고 체크하면 다시 Picker에서 같은 데이터를 선택하더라도 주소값을 다르게 가져가기에 동일한 이미지였는지 체크할 수 없기에 사용
                        if !selectedImages.contains(where: { $0.pngData() == newImage.pngData() }) {
                            
                            DispatchQueue.main.async {
                                selectedImages.append(newImage)
                            }
                        }
                    }
                case .failure:
                    isPresentedError = true
                    
                }
                
            }
        }
        // selectedPhotos를 마지막에 전부 삭제해줌으로 다시 PhotosPicker를 노출했을때 선택했던 이미지의 선택 상태가 풀려있도록 해줍니다.
        selectedPhotos.removeAll()
    }
}
