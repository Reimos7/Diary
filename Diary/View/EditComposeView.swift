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
    // 사진 선택기(Picker)를 보여줄지 여부
    @State private var showPhotoPicker: Bool = false
    //PhotosPicker에서 선택된 사진을 저장하는 배열
    @State private var selectedItems: [PhotosPickerItem] = []
    // 사용자가 선택한 이미지들을 저장하는 배열
    @State private var selectedImages: [UIImage] = []
    //전체 화면에서 이미지를 볼 때 사용하는 변수 (이미지를 클릭하면 설정됨)
    @State private var selectedImageForFullScreen: IdentifiableImage? = nil
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 **경로**(파일 위치)를 저장하는 배열
    @State private var imagePath: [String] = []
    // 에러 감지 상태
    @State private var isPreSentedError: Bool = false
    
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
                ScrollView {
                    if let weatherIcon = data?.currentWearherImage {
                        Image(systemName: weatherIcon)
                        // 아이콘 심볼 이미지를 멀티 컬러 색상으로
                        //.symbolRenderingMode(.multicolor)
                            .resizable()
                            .frame(width: 50,height: 50)
                            .onAppear() {
                                print("\(weatherIcon)")
                            }
                    }
                    //HStack {
                    // 저장된 이미지가 있으면 보여주고 없으면 ProgressView
                    if let paths = data?.imagePath, !paths.isEmpty {
                        ForEach(paths, id: \.self) { path in
                            if let url = URL(string: path) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                    
                                } placeholder: {
                                    ProgressView()
                                }
                                
                            } else {
                                Text("이미지 불러오기 실패")
                            }
                            
                        }
                        
                    }
                    ResizableTextView(text: $content, placeholder: "일기를 입력해주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .focused($focused)
                    
                    
                    Spacer()
                    
                    
                    // 화면이 표시되는 시점에 초기화 코드 구현, 메모가 전달 되었으면 편집할 내용 표시
                    // 키보드 올리기
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.focused = true
                            }
                            
                            if let data = data?.content {
                                content = data
                            }
                        }
                    //}
                    Text(DateFormatter.dateFormatter.string(from: data?.date ?? Date.now))
                        .padding()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            // 키보드 버튼 (현재 시간, 키보드 내리기)
            // EditComposeView는 시뮬레이터에서만 가능하고 실기기에서 사용 불가 코드
            //            .toolbar {
            //                ToolbarItemGroup(placement: .keyboard) {
            //                    Button {
            //                        content += DateFormatter.timeFormatter.string(from: Date())
            //                    } label: {
            //                        Image("clock_img")
            //                            .resizable()
            //                            .scaledToFit()
            //                            .frame(width: 18, height: 18) // SF Symbol 크기와 유사하게 조정
            //                            .symbolRenderingMode(.palette)
            //                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
            //                    }
            //                    Spacer()
            //                    Button {
            //                        hideKeyboard()
            //                    } label: {
            //                        Image("keyboard_img")
            //                            .resizable()
            //                            .scaledToFit()
            //                            .frame(width: 20, height: 20) // SF Symbol 크기와 유사하게 조정
            //                            .symbolRenderingMode(.palette)
            //                            .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
            //                    }
            //                }
            //            }
            
            // 키보드 툴바 - 단일 툴바로 통합
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
                if focused {
                    HStack {
                        Button {
                            content += DateFormatter.timeFormatter.string(from: Date())
                        } label: {
                            Image("clock_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(Color.primary)
                        }
                        
                        Spacer()
                        
                        Button {
                            focused = false
                        } label: {
                            Image("keyboard_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
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
                    // 사진은 일단 1장만 저장
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 1, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                        //.symbolRenderingMode(.hierarchical) // SF Symbol 기본 스타일 유지
                            .foregroundColor(Color(uiColor: UIColor.label)) //  다크모드 대응
                    }
                    .onChange(of: selectedItems) { _, newValue in
                        Task {
                            await updateSelectedImage(newItems: newValue)
                        }
                    }
                    //ToolbarItem(placement: .topBarTrailing) {
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
                    //  }
                    
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
}

