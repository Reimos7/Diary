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
                        //ScrollView(.horizontal, showsIndicators: false) {
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
                            // }
                        }
                        .padding()
                    }
                    //                    ZStack {
                    //                        if content.isEmpty {
                    //                            Text("일기를 입력해주세요!")
                    //                                .foregroundColor(Color(uiColor: .placeholderText))
                    //                        }
                    //                        // 입력을 위한 TextEditor
                    //                        TextEditor(text: $content)
                    //                        //.frame(height: 120)
                    //                            .padding()
                    //                            .focused($focused)
                    //                        //.background(Color(.systemGray6))
                    //                        //.cornerRadius(8)
                    //                            .border(.gray.opacity(0.2), width: 1)
                    //
                    //                        //Spacer()
                    //                    }
                    //                    .padding(.horizontal)
                    //                    .cornerRadius(8)
                    //
                    //                    Spacer()
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
                            manager.addDiaryData(content: content, date: Date())
                            //                        manager.fetchDiaryData(isDecending: true)
                            showToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showToast = false
                                dismiss()
                            }
                        } label: {
                            Image("checkmark_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // SF Symbol 크기와 유사하게 조정
                                .foregroundColor(.primary)
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
                            .foregroundStyle(.black)
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
    
    
    
    //#Preview {
    //    ComposeView(model: .preview)
    //}
}

//                       Button {
//                            // PhotoPickerView를 버튼처럼 사용하기
//                            PhotoPickerView(selectedImages: $selectedImages, isPresentedError: $isPresentedError) {
//                                HStack {
//                                    Image(systemName: "photo.on.rectangle.angled")
//                                }
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundStyle(.white)
//                                .cornerRadius(10)
//                            }
//
//                        }
//                        .padding()
//                        .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
//                            FullscreenImageView(image: fullScreenImage.image)
//                        }
//
//
//                     label: {
//                        Text("이미지")
//                    }
//




