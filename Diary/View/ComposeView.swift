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
                    // ComposeView를 통해 현재 날씨 아이콘을 가져오게 되면 보여주기
                    ZStack {
                        if let model = service.currentWeather {
                            Image(systemName: model.icon)
                                .resizable()
                                .frame(width: 82, height: 72)
                                .offset(x: 1, y: 1)
                                .foregroundStyle(.gray.opacity(0.3))

                            Image(systemName: model.icon)
                                .symbolRenderingMode(.multicolor)
                                .resizable()
                                .frame(width: 80, height: 70)
                                .onAppear {
                                    print(model.icon)
                                }
                        } else {
                            
                        }
                    }
                    .shadow(radius: 2)
                    
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
                                
                                guard let weather = service.currentWeather else {return}
                                
                                for image in selectedImages {
                                    if let path = FileManagerSet.saveImageToFileManager(image: image) {
                                        savedPath.append(path) //  저장된 경로를 추가
                                    }
                                }
                                imagePath = savedPath.isEmpty ? nil : savedPath
                                
                                manager.addDiaryData(content: content, date: Date(), imagePath: imagePath, currentWeatherImage: weather.icon )
                                
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
                    
                    ToolbarItemGroup(placement: .keyboard) {
                        Button {
                            content += DateFormatter.timeFormatter.string(from: Date())
                        } label: {
                            Image("clock_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                        Spacer()
                        Button {
                            hideKeyboard()
                        } label: {
                            Image("keyboard_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focused = true
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
