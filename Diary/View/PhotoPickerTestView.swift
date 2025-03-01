//
//  PhotoPickerTestView.swift
//  Diary
//
//  Created by Reimos on 3/1/25.
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Text("사진을 선택하세요")
            }
            
            PhotosPicker("사진 선택하기", selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                //saveImageToFile(uiImage) // 사진 저장
                            }
                        }
                    }
                }
        }
    }
}
