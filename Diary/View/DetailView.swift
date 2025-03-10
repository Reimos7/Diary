import SwiftUI

// 일기 상세 화면
struct DetailView: View {
    /*
     DetailView에서 공유 버튼을 누르면 DetailView가 내 갤러리에 추가됨
        - Toast 메시지를 통해 사용자에게 캡쳐 된게 저장 됐다고 보여줌
     InfoPlist에서 Privacy - Photo Library Additions Usage Description 이거 추가했음
     CaptureManager 파일을 통해 사진 캡쳐후 저장하는 함수 구현 했음
     3/9일 7시에 했던거임 커밋 푸시 아직 안함
     */
    
    
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
                    // HStack {
                    
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
                    //}
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
            
            // MARK: - 사진 캡쳐 ,편집,삭제 메뉴 버튼
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // ios 14 이하 버전에서 화면 캡쳐 후 앨범에 저장
                        //                        let screenshot = UIApplication.shared.windows.first?.rootViewController?.view.changeUIImage()
                        //                        if let screenshot = screenshot {
                        //                            saveCaptureImageToAlbum(screenshot)
                        //                        }
                        
                        // iOS 15 이상에서 화면 캡처 후 저장
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let screenshot = window.rootViewController?.view.changeUIImage() {
                            // 캡쳐 이미지 저장 Toast 메시지
                            showToast = true
                            saveCaptureImageToAlbum(screenshot)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showToast = false
                            }
                            
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Text("삭제")
                        }
                        
                        Button {
                            showEditComposeView = true
                        } label: {
                            Text("편집")
                        }
                    } label: {
                        Image(systemName:  "ellipsis")
                    }
                }
            } // alert로 삭제
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
}
