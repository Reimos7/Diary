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
    @State private var imageUrl: [URL] = []
    
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss
    
    let data: Diary
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    // 저장된 이미지가 있으면 보여주고 없으면 ProgressView
                    if let paths = data.imagePath, !paths.isEmpty {
                        ForEach(paths, id: \.self) { path in
                            if let url = URL(string: path) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                    // 풀 스크린 이미지 보기
                                        .onTapGesture {
                                            // contentsOfFile 로컬 파일에서 이미지를 불러옴
                                            if let uiImage = UIImage(contentsOfFile: url.path) {
                                                selectedImageForFullscreen = IdentifiableImage(image: uiImage)
                                            }
                                        }
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Text("이미지 불러오기 실패")
                            }
                        }
                    }
                    
                    Text(data.content)
                        .padding()
                    
                    Spacer(minLength: 0)
                    
                    Text(DateFormatter.dateFormatter.string(from: data.date))
                        .padding()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
            }
            // MARK: - 캡쳐 공유, 편집, 삭제 버튼
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // ios 14 이하 버전에서 화면 캡쳐 후 앨범에 저장
                        //                        let screenshot = UIApplication.shared.windows.first?.rootViewController?.view.changeUIImage()
                        //                        if let screenshot = screenshot {
                        //                            saveCaptureImageToAlbum(screenshot)
                        //                        }
                        //
                        //                        iOS 15 이상에서 화면 캡처 후 저장
                        //                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                        //                           let window = windowScene.windows.first,
                        //                           let screenshot = window.rootViewController?.view.changeUIImage() {
                        //                            // 캡쳐 이미지 저장 Toast 메시지
                        //                            showToast = true
                        //                            saveCaptureImageToAlbum(screenshot)
                        //                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        //                                showToast = false
                        //                            }
                        captureScreenShot()
                        screenshotShareAlert = true  // 캡처 후 Alert 표시
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            //.symbolRenderingMode(.hierarchical) // SF Symbol 기본 스타일 유지
                            .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) { showDeleteAlert = true } label: { Text("삭제") }
                        Button { showEditComposeView = true } label: { Text("편집") }
                    } label: {
                        Image(systemName: "ellipsis")
                            //.symbolRenderingMode(.hierarchical) // SF Symbol 기본 스타일 유지
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
                    //                    if let screenshot = screenshotImage {
                    //                        shareScreenShot(screenshot)  // 저장 없이 바로 공유 실행
                    //                    }
                }
            } message: {
                Text("확인을 통해 공유를 시작합니다")
            }
            
            // alert로 삭제
            .alert("삭제", isPresented: $showDeleteAlert) {
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
