//
//  EditComposeView.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import SwiftUI
import PhotosUI

struct EditComposeView: View {
    @State private var content: String = ""
    // X 닫기 버튼을 누르면 현재 화면에서 나갈지 계속 있을지 alert
    @State private var showDismissAlert: Bool = false
    @State private var showToast: Bool = false
    // 선택된 이미지를 길게 눌렀을때
    @State private var isLongPressedPhoto: Bool = false
    //PhotosPicker에서 선택된 사진을 저장하는 배열
    @State private var selectedItems: [PhotosPickerItem] = []
    // 사용자가 선택한 이미지들을 저장하는 배열
    @State private var selectedImages: [UIImage] = []
    //전체 화면에서 이미지를 볼 때 사용하는 변수 (이미지를 클릭하면 설정됨)
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 경로(파일 위치)를 저장하는 배열
    @State private var imagePath: [String] = []
    // 에러 감지 상태
    @State private var isPreSentedError: Bool = false
    
    // 사진 권한 알림 상태
    // 사진 선택기(Picker)를 보여줄지 여부
    @State private var showPhotoPicker: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    @State private var imageUrl: [URL] = []
    // FocusState 이용하여 자동으로 키보드 보여주기
    @FocusState var focused: Bool
    
    let data: Diary?
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        // ComposeView를 통해 현재 날씨 아이콘을 가져오게 되면 보여주기
                        ZStack {
                            if let weatherIcon = data?.currentWeatherImage {
                                Image(systemName: weatherIcon)
                                    .resizable()
                                    .frame(width: 82, height: 72)
                                    .offset(x: 1, y: 1)
                                    .foregroundStyle(.gray.opacity(0.3))
                                
                                Image(systemName: weatherIcon)
                                    .symbolRenderingMode(.multicolor)
                                    .resizable()
                                    .frame(width: 80, height: 70)
                                    .onAppear {
                                        print(weatherIcon)
                                    }
                            } else {
                                
                            }
                        }
                        .shadow(radius: 2)
                        
                        //HStack {
                        // 저장된 이미지가 있으면 보여주고 없으면 ProgressView
                        if let paths = data?.imagePath, !paths.isEmpty {
                            ForEach(paths, id: \.self) { path in
                                if let url = URL(string: path) {
                                    // UIImage로 이미지 로드
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            // 이미지가 성공적으로 로드되면, UIImage로 변환하여 LongPressImageView에 전달
                                            if let uiImage = UIImage(named: path) ?? loadUIImage(from: url) {
                                                LongPressImageView(image: uiImage,
                                                                   imagePath: path,
                                                                   isLongPressedPhoto: $isLongPressedPhoto,
                                                                   selectedImages: $selectedImages,
                                                                   selectedImageForFullscreen: $selectedImageForFullscreen,
                                                                   diaryData: data)
                                            } else {
                                                // 이미지를 UIImage로 변환할 수 없는 경우
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 300, height: 300)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        case .empty:
                                            ProgressView()
                                        case .failure(_):
                                            Text("이미지 로딩 실패")
                                        @unknown default:
                                            ProgressView()
                                        }
                                    }
                                } else {
                                    Text("이미지 불러오기 실패")
                                }
                                
                            }
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
                                //.padding(.leading, 2)
                            }
                            //ResizableTextView(text: $content, placeholder: "일기를 입력해주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                        }
                        .padding()
                        
                        // 텍스트가 변경될 때마다 자동 스크롤 -> 자동 줄 바꿈
                        .onChange(of: content ) { _, _ in
                            withAnimation {
                                proxy.scrollTo("textEditorScroll", anchor: .bottom)
                            }
                        }
                        
                        Spacer()
                        
                        
                        // 화면이 표시되는 시점에 초기화 코드 구현, 메모가 전달 되었으면 편집할 내용 표시
                        // 키보드 올리기
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.focused = true
                                    // 자동 스크롤
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation {
                                            // ScrollViewReader를 통해 textEditorScroll ID로 스크롤 이동
                                            proxy.scrollTo("textEditorScroll", anchor: .top)
                                        }
                                    }
                                }
                                
                                if let data = data?.content {
                                    content = data
                                }
                            }
                        //}
                        Text(DateFormatter.dateFormatter.string(from: data?.date ?? Date.now))
                            .padding()
                            .customFont(size: 16)
                            .foregroundStyle(.secondary)
                    }
                    // 커스텀 키보드 toolbar
                    .customKeyboardToolbar(focused: $focused, content: $content)
                    
                    // PhotoPicker는 권한이 있을 때만 표시
                    .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, maxSelectionCount: 1, matching: .images)
                    .onChange(of: selectedItems) { _, newValue in
                        Task {
                            await updateSelectedImage(newItems: newValue)
                            
                            // 이미지 변경 후 자동 스크롤
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation {
                                    // ScrollViewReader를 통해 textEditorScroll ID로 스크롤 이동
                                    proxy.scrollTo("textEditorScroll", anchor: .top)
                                }
                            }
                        }
                        // 새로운 이미지 선택시 휴지통 버튼 초기화
                        isLongPressedPhoto = false
                    }
                    
                    // 권한 알림을 위한 알림창
//                    .alert(isPresented: $showPermissionAlert) {
//                        Alert(
//                            title: Text("사진 접근 권한"),
//                            message: Text(permissionMessage),
//                            primaryButton: .default(Text("설정")) {
//                                PhotoPermissionManager.openPhotoSetting()
//                            },
//                            secondaryButton: .cancel(Text("취소"))
//                        )
//                    }
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

                    
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                showDismissAlert = true
                            }
                            label: {
                                Image(systemName: "xmark")
                                //.symbolRenderingMode(.hierarchical) // SF Symbol 기본 스타일 유지
                                    .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                            }
                        }
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            // 사진은 일단 1장만 저장 - 권한 체크 후 바로 포토 피커 표시
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
                                guard let data = data else { return }
                                manager.updateDiaryData(entry: data, newContent: content)
                                // 수정 버튼 누르면 키보드 내려서 showToast 사용자에게 보여주기
                                self.focused = false
                                
                                showToast = true
                                // 저장하면 toast 메시지로 알려주고 1초 뒤에 dissmiss 실행
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showToast = false
                                    dismiss()
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
                    .alert("글 작성을 그만하시나요?", isPresented: $showDismissAlert) {
                        Button("나가기", role: .destructive) {
                            dismiss()
                        }
                        
                        Button("계속 작성", role: .cancel) {
                            showDismissAlert = false
                        }
                    } message: {
                        Text("작성한 글이 저장되지 않습니다!")
                    }
                    
                    // 저장하면 toast 메시지로 알려줌
                    if showToast {
                        VStack {
                            Text("일기를 수정했어요!")
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
    }
    
    // MARK: - 사진 권한 체크 및 포토 피커 표시 함수
    private func checkPhotoPermission() {
        PhotoPermissionManager.checkPhotoLibraryPermission { status in
            switch status {
            case .authorized:
                // 권한이 있으면 사진 선택기 바로 표시
                self.showPhotoPicker = true
            case .limited:
                // 제한된 권한도 일단 PhotoPicker 표시하고 메시지로 알림
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                // 제한된 권한이 있으면 사진 선택기 바로 표시
                self.showPhotoPicker = true
                // self.showPhotoPermissionAlert = true
            case .denied, .restricted:
                // 권한이 거부된 경우 알림 표시
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                self.showPermissionAlert = true
            case .notDetermined:
                // notDetermined 상태는 checkPhotoLibraryPermission 메서드에서 처리됨
                // 권한 요청 후 콜백에서 다시 이 메서드가 호출됨
                break
            @unknown default:
                break
            }
        }
    }
    
    // 사용자가 새 이미지를 선택하면 기존 이미지를 삭제하고 새로운 이미지를 저장
    private func updateSelectedImage(newItems: [PhotosPickerItem]) async {
        guard let data = data else {return}
        
        // 기존 이미지 삭제 (파일 + SwiftData에서 경로 삭제함)
        if let paths = data.imagePath {
            for path in paths {
                FileManagerSet.deleteImageFromFileManager(at: path)
                print("기존 이미지와 경로를 삭제했습니다: \(path)")
            }
        }
        
        // SwiftData에서 기존 경로 삭제
        data.imagePath = nil // 기존 이미지 경로 제거
        try? manager.saveContext() // SwiftData 변경 사항 저장
        
        // 기존 UI 데이터 초기화
        imagePath.removeAll()
        selectedItems.removeAll()
        
        // 새로운 이미지 추가
        for item in newItems {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                if let savedPath = FileManagerSet.saveImageToFileManager(image: image) {
                    imagePath.append(savedPath)
                }
                DispatchQueue.main.async {
                    selectedImages.append(image)
                }
            }
        }
        // SwiftData에 새로운 이미지 경로 업데이트
        data.imagePath = imagePath.isEmpty ? nil : imagePath
        try? manager.saveContext() // 변경 사항 바로 저장
    }
    
    // URL에서 UIImage 로드하는 함수 추가
    func loadUIImage(from url: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data)
        } catch {
            print("이미지 로드 실패: \(error)")
            return nil
        }
    }
}
