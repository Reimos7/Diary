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
    // 선택된 이미지를 길게 눌렀을때
    @State private var isLongPressedPhoto: Bool = false
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
        ScrollViewReader { proxy in
            ScrollView {
            NavigationStack {
                VStack(spacing: 0) {
                    // ComposeView를 통해 현재 날씨 아이콘을 가져오게 되면 보여주기
                    ZStack {
                        // 위치 권한이 거부된 상태라면
                        if service.showLocationDeniedWeatherView {
                            Text("위치 권한을 허용하면 날씨를 기록할 수 있어요!\n")
                        } else {
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
                            }
                        }/*else if service.showLocationDeniedWeatherView {
                            Text("위치 권한을 허용하면 날씨를 기록할 수 있어요!\n")
                        }*/
                    }
                    .shadow(radius: 2)
                    
                    Text(DateFormatter.dateFormatter.string(from: Date())) // 2025년 2월 5일 (수요일)
                    //.padding(.bottom, 2)
                    
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
                                //.padding(.leading, 2)
                        }
                        //ResizableTextView(text: $content, placeholder: "일기를 입력해주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                    }
                    .padding()
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
                            Image("gallery_img")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26) // SF Symbol 크기와 유사하게 조정
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.primary) // 다크 모드에서 자동으로 흰색 적용
                        }
                        .onChange(of: selectedItems) { _, newValue in
                            Task { // 선택한 사진을 앱에 추가하는 비동기 작업 수행
                                for item in newValue {
                                    // item.loadTransferable(type: Data.self) - 선택한 사진을 “파일 데이터”로 변환하는 작업
                                    // 변환된 데이터를 UIImage로 변환하여 앱에서 표시할 수 있는 이미지로 만듦
                                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                        // 새로운 이미지 선택시 휴지통 버튼 초기화
                                        isLongPressedPhoto = false
                                        // UI 업데이트는 메인 스레드에서 실행해야함 - 사진 추가는 UI 업데이트 작업이니까 메인 스레드에서 하기
                                        DispatchQueue.main.async {
                                            // 선택한 이미지 저장
                                            // append로 하지말고 배열 전체를 덮어 쓰게해서 1장만 선택하게
                                            selectedImages = [image]
                                            //selectedImages.append(image)
                                            
                                            // 이미지 추가 후 자동 스크롤
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                withAnimation {
                                                    // ScrollViewReader를 통해 textEditorScroll ID로 스크롤 이동
                                                    proxy.scrollTo("textEditorScroll", anchor: .top)
                                                }
                                            }
                                        }
                                    }
                                    //selectedItems.removeAll()
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
                                
                                // 현재 위치 즉, 날씨 정보 존재 유무에 따른 분기 처리
                                guard let weather = service.currentWeather else {
                                    // 날씨 정보가 없을때
                                    print("날씨 정보가 없을때 호출됨 ")
                                    manager.addDiaryData(content: content, date: Date(), imagePath: imagePath, currentWeatherImage: nil)
                                    
                                    //manager.fetchDiaryData(isDecending: true)
                                    
                                    // 저장 버튼을 누르면 키보드 내려서 showToast 사용자에게 보여주기
                                    self.focused = false
                                    
                                    showToast = true
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        showToast = false
                                        dismiss()
                                    }
                                    return
                                }
                                
//                                for image in selectedImages {
//                                    if let path = FileManagerSet.saveImageToFileManager(image: image) {
//                                        savedPath.append(path) //  저장된 경로를 추가
//                                    }
//                                }
                                //imagePath = savedPath.isEmpty ? nil : savedPath
                                
                                manager.addDiaryData(content: content, date: Date(), imagePath: imagePath, currentWeatherImage: weather.icon)
                                
                                //manager.fetchDiaryData(isDecending: true)
                                
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
    }
        // 이거는 안됨
        //.ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
