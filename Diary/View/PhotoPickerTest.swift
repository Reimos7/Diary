import SwiftUI
import PhotosUI

struct PhotoPickerTest: View {
    @State private var selectedPhotos: [PhotosPickerItem] = []
    // 선택된 이미지 저장
    @State private var selectedImages: [UIImage] = []
    //에러 감지 상태
    @State private var isPresentedError: Bool = false
    // 클릭한 이미지 저장
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    
    
    var body: some View {
        VStack {
            // 선택한 이미지 미리보기
            if !selectedImages.isEmpty {
                ScrollView {
                    VStack {
                        ForEach(selectedImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    selectedImageForFullscreen = IdentifiableImage(image: image)
                                }
                        }
                        
                    }
                }
                .padding()
            }
            
            // PhotoPickerView를 버튼처럼 사용하기
            PhotoPickerView(selectedPhotos: $selectedPhotos, selectedImages: $selectedImages, isPresentedError: $isPresentedError) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                }
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            
        }
        .padding()
        .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
            FullscreenImageView(image: fullScreenImage.image)
        }
    }
}


#Preview {
    PhotoPickerTest()
}
