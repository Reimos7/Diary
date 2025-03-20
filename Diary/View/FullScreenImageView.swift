//
//  FullScreenImageView.swift
//  Diary
//
//  Created by Reimos on 3/3/25.
//

import SwiftUI

//  Identifiable을 따르는 구조체
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct FullscreenImageView: View {
    var image: UIImage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // 이미지 표시
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 닫기버튼 x버튼 좌측으로
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.primary) 
                            .padding()
                    }

                    Spacer()
                }
                Spacer()
            }
            
            
        }
    }
}
