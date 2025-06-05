import SwiftUI

struct DetailView: View {
    @State private var screenshotImage: UIImage? = nil
    @State private var screenshotShareAlert: Bool = false
    // 스크린샷이 저장되면 사용자에게 Toast 메시지로 보여주기
    @State private var showToast: Bool = false
    @State private var showEditComposeView: Bool = false
    @State private var showDeleteAlert: Bool = false
    // 클릭한 이미지 풀 스크린
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    //@State private var imageUrl: [URL] = []
    
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss
    
    let data: Diary
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    // ComposeView를 통해 현재 날씨 아이콘을 가져오게 되면 보여주기
                    ZStack {
                        if let weatherIcon = data.currentWeatherImage {
                            Image(systemName: weatherIcon)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 100, maxHeight: 100)
                                .offset(x: 1, y: 1)
                                .foregroundStyle(.gray.opacity(0.3))
                            
                            Image(systemName: weatherIcon)
                                .symbolRenderingMode(.multicolor)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 100, maxHeight: 100)
                                .onAppear {
                                    print(weatherIcon)
                                    if let imagePaths = data.imagePath {
                                            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

                                            for fileName in imagePaths {
                                                let fileURL = directory.appendingPathComponent(fileName)
                                                let exists = FileManager.default.fileExists(atPath: fileURL.path)
                                                print(" \(fileName) → 존재 여부: \(exists ? "있음" : "없음")")
                                            }
                                        } else {
                                            print("imagePath가 nil 또는 비어 있음")
                                        }
                                    print("저장된 imagePath: \(data.imagePath ?? ["없음"])")
                                }
                        } else {
                            
                        }
                    }
                    .shadow(radius: 2)
                    
                    Text(DateFormatter.dateFormatter.string(from: data.date))
                        .padding()
                        .customFont(size: 16)
                    //.foregroundStyle(.secondary)
                
                    if let paths = data.imagePath, !paths.isEmpty {
                        ForEach(paths, id: \.self) { fileName in
                            // 파일명을 받아 실제 UIImage로 변환
                            if let image = FileManagerSet.loadImageFromFileManager(fileName: fileName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 300)
                                    .onTapGesture {
                                        selectedImageForFullscreen = IdentifiableImage(image: image)
                                    }
                            } else {
                                Text("이미지를 불러올 수 없습니다")
                            }
                        }
                    }
                    
                    Text(data.content)
                        .padding()
                    
                    Spacer(minLength: 0)
                    
                }
            }
            // 이미지 클릭 시 전체 화면 표시
            .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
                FullscreenImageView(image: fullScreenImage.image)
            }
            // 기본 뒤로 가기 버튼 숨김
            .navigationBarBackButtonHidden()
            // 스와이프 뒤로 가기 활성화 UIKit의 interactivePopGestureRecognizer 사용
            .background(NavigationControllerWrapper())
            
            // MARK: - 캡쳐 공유, 편집, 삭제 버튼
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 뒤로 가기 버튼
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // 뒤로 가기 동작 (현재 뷰 닫기)
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(uiColor: UIColor.label))
                    }
                    .tint(.clear) // 버튼에 기본 tint 색(파란색) 무력화
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        captureScreenShot()
                        screenshotShareAlert = true  // 캡처 후 Alert 표시
                    } label: {
                        Image("share_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26) // SF Symbol 크기와 유사하게 조정
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                    }
                    
                    Menu {
                        Button(role: .destructive) { showDeleteAlert = true } label: { Text("삭제") }
                        Button { showEditComposeView = true } label: { Text("편집") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                    }
                }
                
            }
            .alert("일기를 앨범에 저장하시겠습니까?", isPresented: $screenshotShareAlert) {
                Button("확인") {
                    if let screenshot = screenshotImage {
                        saveCaptureImageToAlbum(screenshot)  // 앨범 저장
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showToast = false
                        }
                        shareScreenShot(screenshot)  //  저장 후 공유 실행
                    }
                }
                
                Button("취소", role: .cancel) {
                }
            } message: {
                Text("확인을 통해 공유를 시작합니다")
            }
            
            // alert로 삭제
            .alert("삭제", isPresented: $showDeleteAlert) {
                Button(role: .cancel) {
                } label: {
                    Text("취소")
                }
                Button(role: .destructive) {
                    manager.deleteDiaryData(entry: data)
                    dismiss()
                } label: {
                    Text("삭제")
                }
            } message: {
                Text("일기를 삭제할까요?")
            }
            
            
            .fullScreenCover(isPresented: $showEditComposeView) {
                EditComposeView(data: data)
            }
            // 캡쳐 이미지를 저장하면 Toast 메시지로 알려줌
            if showToast {
                VStack {
                    Text("스크린샷 앨범 저장 성공")
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showToast)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func captureScreenShot() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let screenshot = window.rootViewController?.view.changeUIImage() {
            self.screenshotImage = screenshot
        }
    }
    
    //  기본 공유 시트에서 "이미지 + 텍스트"를 포함하도록 수정
    private func shareScreenShot(_ screenshot: UIImage) {
        let shareText = "일기 캡쳐본"
        let activityViewController = UIActivityViewController(activityItems: [shareText, screenshot], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}
