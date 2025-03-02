import SwiftUI

//  Identifiable을 따르는 구조체
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct PhotoPickerTest: View {
    @State private var selectedImages: [UIImage] = [] // 선택된 이미지 저장
    @State private var isPresentedError: Bool = false // 에러 감지 상태
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil // 클릭한 이미지 저장

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
                                    selectedImageForFullscreen = IdentifiableImage(image: image) //  래퍼로 감싸서 저장
                                }
                        }
                    }
                }
                .padding()
            }
            
            //  `PhotoPickerView`를 버튼처럼 사용
            PhotoPickerView(selectedImages: $selectedImages, isPresentedError: $isPresentedError) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title)
                    Text("사진 선택하기")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .fullScreenCover(item: $selectedImageForFullscreen) { identifiableImage in
            FullscreenImageView(image: identifiableImage.image) //  래퍼에서 이미지 추출
        }
    }
}

struct FullscreenImageView: View {
    var image: UIImage
    @Environment(\.dismiss) var dismiss // 닫기 기능 제공

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 이미지 표시
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 닫기 버튼 (X)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss() //  X 버튼을 누르면 닫기
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    PhotoPickerTest()
}
