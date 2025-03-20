//
//  ComposeView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import SwiftUI
import PhotosUI

// 글쓰기 버튼 누르면 실행 되는 뷰 (오늘 날짜만)
struct ComposeView: View {
    @State private var content: String = ""
    @State private var showToast: Bool = false
    @State private var showPhotoPicker: Bool = false
    // 선택된 이미지 저장
    @State private var selectedImages: [UIImage] = []
    //에러 감지 상태
    @State private var isPresentedError: Bool = false
    // 클릭한 이미지 저장
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    //직접 실행할 PhotosPicker
    @State private var selectedItems: [PhotosPickerItem] = []
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    @State private var imagePath: [String]? = nil
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: WeatherService
    @EnvironmentObject var manager: SwiftDataManager
    // FocusState 이용하여 자동으로 키보드 보여주기
    @FocusState var focused: Bool
    
    let model: CurrentWeather?
    
    var body: some View {
        ScrollView {
            NavigationStack {
                VStack(spacing: 0) {
                    if let model = service.currentWeather {
                        Image(systemName: model.icon)
                        // 아이콘 심볼 이미지를 멀티 컬러 색상으로
                        //.symbolRenderingMode(.multicolor)
                            .resizable()
                            .frame(width: 50,height: 50)
                            .onAppear() {
                                print("\(model.icon)")
                            }
                    }
                    
                    Text(DateFormatter.dateFormatter.string(from: Date())) // 2025년 2월 5일 (수요일)
                    //.padding(.bottom, 2)
                    
                    // 선택한 이미지 출력
                    if !selectedImages.isEmpty {
                        
                        VStack(spacing: 5) {
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
                        .padding()
                    }
                    ResizableTextView(text: $content, placeholder: "일기를 입력해주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .focused($focused)
                    
                    
                    Spacer()
                    
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focused = true
                    }
                }
                
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        // 일단 사진은 1장만 저장
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                        }
                        .onChange(of: selectedItems) { _, newValue in
                            Task {
                                for item in newValue {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        DispatchQueue.main.async {
                                            selectedImages.append(image)
                                        }
                                    }
                                }
                                
                            }
                            
                        }
                        Button {
                            
                            Task {
                                var savedPath: [String] = []
                                
                                for image in selectedImages {
                                    if let path = FileManagerSet.saveImageToFileManager(image: image) {
                                        savedPath.append(path) //  저장된 경로를 추가
                                    }
                                }
                                imagePath = savedPath.isEmpty ? nil : savedPath
                                
                                manager.addDiaryData(content: content, date: Date(), imagePath: imagePath)
                                // manager.fetchDiaryData(isDecending: true)
                                
                                // 저장 버튼을 누르면 키보드 내려서 showToast 사용자에게 보여주기
                                self.focused = false
                                
                                showToast = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showToast = false
                                    dismiss()
                                }
                                
                            }
                        } label: {
                            Image("checkmark_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                    }
                }
                // 이미지 클릭 시 전체 화면 표시
                .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
                    FullscreenImageView(image: fullScreenImage.image)
                }
                
                // 저장하면 toast 메시지로 알려줌
                if showToast {
                    VStack {
                        Text("일기를 저장했어요!")
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary) // 다크모드에서도 자동 변경
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: showToast)
                    .padding(.bottom, 50)
                    
                }
                
            }
        }
        // 이거는 안됨
        //.ignoresSafeArea(.keyboard, edges: .bottom)
    }
}





