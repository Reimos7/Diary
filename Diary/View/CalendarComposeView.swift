//
//  FSCalenderComposeView.swift
//  Diary
//
//  Created by Reimos on 2/19/25.
//

import SwiftUI
import PhotosUI

// MARK: - 사용자가 캘린더에서 날짜를 선택하면 실행
struct CalendarComposeView: View {
    //let selectedDate: Date
    @State private var content: String = ""
    @State private var showToast: Bool = false
    // 사진 선택기(Picker)를 보여줄지 여부
    @State private var showPhotoPicker: Bool = false
    // PhotosPicker에서 선택된 사진을 저장하는 배열
    @State private var selectedItems: [PhotosPickerItem] = []
    // 사용자가 선택한 이미지들을 저장하는 배열
    @State private var selectedImages: [UIImage] = []
    // 전체 화면에서 이미지를 볼 때 사용하는 변수 (이미지를 클릭하면 설정됨)
    @State private var selectedImageForFullScreen: IdentifiableImage? = nil
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 **경로**(파일 위치)를 저장하는 배열
    @State private var imagePath: [String]? = nil
    // 에러 감지 상태
    @State private var isPreSentedError: Bool = false
    
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    // TextEditor에서 사용자가 입력할 때 키보드를 자동으로 보여주거나 숨길 수 있도록 도와줌
    @FocusState var focused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 캘린더에서 선택한 날짜를 보여줌
                Text(DateFormatter.dateFormatter.string(from:selectedDate))
                
                // 선택한 이미지 표시
                if !selectedImages.isEmpty {
                    VStack(spacing: 5) {
                        ForEach(selectedImages, id: \.self) {
                            image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture {
                                    selectedImageForFullScreen = IdentifiableImage(image: image)
                                }
                        }
                    }
                    .padding()
                }

                // 입력을 위한 커스텀 TextEditor (자동 줄 바꿈)
                ResizableTextView(text: $content, placeholder: "일기를 입력해 주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                    .padding()
                    // 포커스를 맞춰서 화면이 열리면 키보드 자동으로 올라오게 함
                    .focused($focused)
                Spacer()
            }
            // 화면이 나타난 후 0.5초 뒤에 키보드를 자동으로 올림
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.focused = true
                }
            }
            
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // 사진은 일단 1장만 저장
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                    }
                    .onChange(of: selectedItems) { _, newValue in
                        Task { // 선택한 사진을 앱에 추가하는 비동기 작업 수행
                            for item in newValue {
                                // item.loadTransferable(type: Data.self) - 선택한 사진을 “파일 데이터”로 변환하는 작업
                                // 변환된 데이터를 UIImage로 변환하여 앱에서 표시할 수 있는 이미지로 만듦
                                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                    // UI 업데이트는 메인 스레드에서 실행해야함 - 사진 추가는 UI 업데이트 작업이니까 메인 스레드에서 하기
                                    DispatchQueue.main.async {
                                        // 선택한 이미지 저장
                                        selectedImages.append(image)
                                    }
                                }
                            }
                        }
                    }
                    Button {
                        Task {
                            var savedPath: [String] = []
                            // 선택한 이미지들을 파일로 저장하고, 저장된 경로를 기록
                            for image in selectedImages {
                                if let path = FileManagerSet.saveImageToFileManager(image: image) {
                                    // 저장된 경로 추가
                                    savedPath.append(path)
                                }
                            }
                            // 이미지가 없으면 nil 처리
                            imagePath = savedPath.isEmpty ? nil : savedPath
                            // 일기 데이터를 SwiftDataManager를 통해 저장, 캘린더에서 선택한 날짜로 저장
                            manager.addDiaryData(content: content, date: selectedDate, imagePath: imagePath)
                            
                            // 저장 버튼을 누르면 키보드 내려서 사용자에게 showToast 보여주기
                            self.focused = false
                            
                            showToast = true
                            
                            // showToast 보여주고 1초 뒤에 dissmiss
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showToast = false
                                dismiss()
                            }
                        }
                    } label: {
                        Image("checkmark_img")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                    }
                }
            }
            // 이미지 클릭 시 전체 화면 표시
            .fullScreenCover(item: $selectedImageForFullScreen) { fullScreenImage in FullscreenImageView(image: fullScreenImage.image)
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
}

