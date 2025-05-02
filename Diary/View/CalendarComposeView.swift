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
    // 선택된 이미지를 길게 눌렀을때
    @State private var isLongPressedPhoto: Bool = false
    // PhotosPicker에서 선택된 사진을 저장하는 배열
    // 클릭한 이미지 저장
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    //직접 실행할 PhotosPicker
    @State private var selectedItems: [PhotosPickerItem] = []
    // 사용자가 선택한 이미지들을 저장하는 배열
    @State private var selectedImages: [UIImage] = []
    // 전체 화면에서 이미지를 볼 때 사용하는 변수 (이미지를 클릭하면 설정됨)
    @State private var selectedImageForFullScreen: IdentifiableImage? = nil
    // [리팩토링] 절대경로 대신 파일명만 저장
    @State private var imagePath: [String]? = nil
    // 에러 감지 상태
    @State private var isPreSentedError: Bool = false
    
    // 사진 권한 관련 상태
    // 사진 선택기(Picker)를 보여줄지 여부
    @State private var showPhotoPicker: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""
    
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    // TextEditor에서 사용자가 입력할 때 키보드를 자동으로 보여주거나 숨길 수 있도록 도와줌
    @FocusState var focused: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // 캘린더에서 선택한 날짜를 보여줌
                    Text(DateFormatter.dateFormatter.string(from:selectedDate))
                    
                    // 선택한 이미지 출력
                    if !selectedImages.isEmpty {
                        VStack(spacing: 5) {
                            ForEach(selectedImages, id: \.self) { image in
                                // 이미지를 길게 눌렀을때 휴지통 버튼을 통해 이미지 지우기
                                LongPressImageView(image: image, isLongPressedPhoto: $isLongPressedPhoto, selectedImages: $selectedImages, selectedImageForFullscreen: $selectedImageForFullscreen)
                            }
                        }
                        .padding()
                    }
                    // 일기 입력 부분
                    ZStack(alignment: .topLeading) {
                        
                        TextEditor(text: $content)
                        // TextEditor 기본 여백 때문에 좌우 바깥 공간을 5만큼 줄이기
                            .padding(.horizontal, -5)
                        // 포커스를 맞춰서 화면이 열리면 키보드 자동으로 올라오게 함
                            .focused($focused)
                        // 스크롤 타겟 ID , 스크롤 대상으로 설정
                            .id("textEditorScroll")
                        
                        // placeholder - TextEidtor는 기본 제공 안됨
                        if content.isEmpty {
                            Text("일기를 입력해 주세요!")
                                .foregroundStyle(.gray)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                }
                // 화면이 나타난 후 0.5초 뒤에 키보드를 자동으로 올림
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focused = true
                    }
                }
                
                // 텍스트가 변경될 때마다 자동 스크롤 -> 자동 줄 바꿈
                .onChange(of: content ) { _, _ in
                    withAnimation {
                        proxy.scrollTo("textEditorScroll", anchor: .bottom)
                    }
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
                        // 사진 버튼을 눌렀을 때 권한 확인 후 PhotosPicker 표시
                        Button {
                            checkPhotoPermission()
                        } label: {
                            Image("gallery_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                        
                        Button {
                            Task {
                                var savedFileNames: [String] = []
                                
                                for image in selectedImages {
                                    // fileName는 실제 경로가 아니라 파일명
                                    if let fileName = FileManagerSet.saveImageToFileManager(image: image) {
                                        // 저장에 성공한 파일명을 배열에 추가
                                        savedFileNames.append(fileName)
                                    }
                                }
                                // 이미지가 없으면 nil 처리
                                imagePath = savedFileNames.isEmpty ? nil : savedFileNames
                                
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
            // 커스텀 키보드 toolbar
            .customKeyboardToolbar(focused: $focused, content: $content)
            
            // PhotoPicker는 권한이 있을 때만 표시
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, maxSelectionCount: 1, matching: .images)
            .onChange(of: selectedItems) { _, newValue in
                Task { // 선택한 사진을 앱에 추가하는 비동기 작업 수행
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            // 새로운 이미지 선택시 휴지통 버튼 초기화
                            isLongPressedPhoto = false
                            // UI 업데이트는 메인 스레드에서 실행해야함
                            DispatchQueue.main.async {
                                // 선택한 이미지 저장 (1장만 선택)
                                selectedImages = [image]
                                
                                // 이미지 추가 후 자동 스크롤
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo("textEditorScroll", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // 권한 거부된 경우 알림
            .alert(permissionMessage, isPresented: $showPermissionAlert) {
                Button("취소") {
                    
                }
                // 설정으로 이동 후 사용자에게 권한 설정 유도
                if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .denied ||
                    PHPhotoLibrary.authorizationStatus(for: .readWrite) == .restricted {
                    Button("설정") {
                        PhotoPermissionManager.openPhotoSetting()
                    }
                }
            }
        }
    }
    
    // MARK: - 사진 권한 체크 및 포토 피커 표시 함수
    private func checkPhotoPermission() {
        PhotoPermissionManager.checkPhotoLibraryPermission { status in
            switch status {
            case .authorized:
                // 권한이 허용된 경우 PhotoPicker 표시
                self.showPhotoPicker = true
            case .limited:
                // 제한된 권한도 일단 PhotoPicker 표시하고 메시지로 알림
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                //self.showPermissionAlert = true
                self.showPhotoPicker = true
            case .denied, .restricted:
                // 권한이 거부된 경우 알림 표시
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                self.showPermissionAlert = true
            case .notDetermined:
                // 권한이 결정되지 않은 경우 (이미 처리되었을 것이므로 일반적으로 여기까지 오지 않음)
                break
            @unknown default:
                break
            }
        }
    }
}

