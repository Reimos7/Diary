//
//  ComposeView.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//  새 디자인: 상세 화면과 동일한 틀로 통일 (작성할 때부터 감성적인 모습).
//  틀: [사진] → 날짜(우측) → 가로 구분선 → 왼쪽 세로선 [우측 날씨 + 가운데 본문(입력)]
//  기능(사진 첨부/권한, 저장, 키보드 툴바, 자동 스크롤, 토스트)은 기존 그대로 유지.
//

import SwiftUI
import PhotosUI

// 글쓰기 버튼 누르면 실행 되는 뷰 (오늘 날짜만)
struct ComposeView: View {
    @State private var content: String = ""
    @State private var showToast: Bool = false
    @State private var isLongPressedPhoto: Bool = false
    @State private var selectedImages: [UIImage] = []
    @State private var isPresentedError: Bool = false
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var imagePath: [String]? = nil

    // 사진 권한 관련 상태
    @State private var showPhotoPicker: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var service: WeatherService
    @EnvironmentObject var manager: SwiftDataManager
    @FocusState var focused: Bool

    let model: CurrentWeather?

    // 사진 보유 여부 (작성 중 선택된 이미지 기준)
    private var hasPhotos: Bool { !selectedImages.isEmpty }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // 1) 사진 블록 — 선택했을 때만. 상세 화면처럼 전체 너비 히어로.
                        if hasPhotos {
                            photoSection
                        }

                        // 2) 날짜 (우측 정렬)
                        dateSection

                        // 3) 가로 구분선 (전체 너비)
                        Rectangle()
                            .fill(AppColor.divider)
                            .frame(height: 1)

                        // 4) 왼쪽 세로선 + [우측 날씨 + 가운데 본문(입력)]
                        contentSection(fillHeight: fillHeight(for: geo.size.height), proxy: proxy)
                    }
                }
                .background(AppColor.background.ignoresSafeArea())
                // 사진이 있으면 네비게이션 바 밑까지 꽉 차게
                .ignoresSafeArea(edges: hasPhotos ? .top : [])
                .onChange(of: content) { _, _ in
                    withAnimation { proxy.scrollTo("textEditorScroll", anchor: .bottom) }
                }
                .navigationBarBackButtonHidden()
                .background(NavigationControllerWrapper())
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar { toolbarContent }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focused = true
                    }
                    AnalyticsManager.log(.composeStarted(entryPoint: "main"))
                }
                .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
                    FullscreenImageView(image: fullScreenImage.image)
                }
                .customKeyboardToolbar(focused: $focused, content: $content)
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, maxSelectionCount: 1, matching: .images)
                .onChange(of: selectedItems) { _, newValue in
                    Task {
                        for item in newValue {
                            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                                isLongPressedPhoto = false
                                DispatchQueue.main.async {
                                    selectedImages = [image]
                                }
                            }
                        }
                    }
                }
                .alert(permissionMessage, isPresented: $showPermissionAlert) {
                    Button("취소") {}
                    if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .denied ||
                        PHPhotoLibrary.authorizationStatus(for: .readWrite) == .restricted {
                        Button("설정") { PhotoPermissionManager.openPhotoSetting() }
                    }
                }
                // 저장 완료 토스트
                .overlay(alignment: .bottom) {
                    if showToast {
                        Text("일기를 저장했어요!")
                            .customFont(size: 15)
                            .padding()
                            .background(AppColor.surface)
                            .foregroundStyle(AppColor.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                            .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
                            .transition(.opacity)
                            .animation(.easeInOut, value: showToast)
                            .padding(.bottom, 50)
                    }
                }
            }
        }
    }

    // MARK: - 사진 블록 (전체 너비 히어로 + 삭제 버튼)

    private var photoSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(selectedImages, id: \.self) { image in
                ZStack {
                    // 전체 너비 히어로 사진 (상세 화면과 동일한 모습)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 340)
                        .clipped()
                        // 하단을 크림색으로 부드럽게 페이드
                        .overlay(alignment: .bottom) {
                            LinearGradient(colors: [.clear, AppColor.background],
                                           startPoint: .top, endPoint: .bottom)
                                .frame(height: 90)
                                .allowsHitTesting(false)
                        }
                        // 길게 누르면 어두워짐 (삭제 모드 표시)
                        .colorMultiply(isLongPressedPhoto ? .gray : .white)
                        .onTapGesture {
                            selectedImageForFullscreen = IdentifiableImage(image: image)
                        }
                        .onLongPressGesture {
                            isLongPressedPhoto.toggle()
                        }

                    // 길게 누른 상태면 가운데 휴지통 버튼 표시 (기존 방식)
                    if isLongPressedPhoto {
                        Button {
                            if let index = selectedImages.firstIndex(of: image) {
                                selectedImages.remove(at: index)
                            }
                            isLongPressedPhoto = false
                        } label: {
                            Image("trash_img")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding()
                                .background(AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                        }
                    }
                }
            }
        }
    }

    // MARK: - 날짜 (우측 정렬)

    private var dateSection: some View {
        HStack {
            Spacer()
            Text(DateFormatter.dateFormatter.string(from: Date()))
                .customFont(size: 17)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - 본문 영역 (왼쪽 세로선 + 우측 날씨 + 가운데 입력)

    private func contentSection(fillHeight: CGFloat, proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 0) {
            // 왼쪽 세로선 (아래까지)
            Rectangle()
                .fill(AppColor.divider)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            VStack(spacing: AppSpacing.md) {
                // 날씨 (우측 정렬)
                weatherBlock
                    .frame(maxWidth: .infinity, alignment: .trailing)

                // 본문 입력 (가운데 정렬)
                ZStack(alignment: .top) {
                    TextEditor(text: $content)
                        .customFont(size: 17)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .scrollContentBackground(.hidden)
                        .background(AppColor.background)
                        .frame(minHeight: 220)
                        .focused($focused)
                        .id("textEditorScroll")

                    // placeholder — TextEditor 위에 겹쳐서 표시 (커서와 같은 가운데 상단 위치)
                    if content.isEmpty {
                        Text("일기를 입력해 주세요!")
                            .customFont(size: 17)
                            .foregroundStyle(AppColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .frame(minHeight: fillHeight)
        // 왼쪽 세로선을 화면 끝에서 살짝 안쪽으로 (공책 여백선)
        .padding(.leading, AppSpacing.md)
    }

    // MARK: - 날씨 블록 (우측 정렬)

    @ViewBuilder
    private var weatherBlock: some View {
        if service.showLocationDeniedWeatherView {
            Text("위치 권한을 허용하면\n날씨를 기록할 수 있어요")
                .customFont(size: 13)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.trailing)
        } else if let model = service.currentWeather {
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                WeatherIconView(symbol: model.icon, size: 60)
                Text(model.weather)
                    .customFont(size: 14)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    /// 세로선이 아래까지 채워지도록 본문 영역 최소 높이 계산.
    private func fillHeight(for totalHeight: CGFloat) -> CGFloat {
        let reserved: CGFloat = hasPhotos ? 400 : 140
        return max(totalHeight - reserved, 240)
    }

    // MARK: - 툴바 (기존 기능 유지)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppColor.textPrimary)
            }
            .tint(.clear)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                checkPhotoPermission()
            } label: {
                Image("gallery_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Button {
                saveDiary()
            } label: {
                Image("checkmark_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    // MARK: - 저장 (기존 로직 유지)

    private func saveDiary() {
        Task {
            var savedFileNames: [String] = []
            for image in selectedImages {
                if let fileName = FileManagerSet.saveImageToFileManager(image: image) {
                    savedFileNames.append(fileName)
                }
            }
            imagePath = savedFileNames.isEmpty ? nil : savedFileNames

            let weatherIcon = service.currentWeather?.icon
            manager.addDiaryData(content: content, date: Date(), imagePath: imagePath, currentWeatherImage: weatherIcon)

            self.focused = false
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showToast = false
                dismiss()
            }
        }
    }

    // MARK: - 사진 권한 체크

    private func checkPhotoPermission() {
        PhotoPermissionManager.checkPhotoLibraryPermission { status in
            switch status {
            case .authorized:
                self.showPhotoPicker = true
            case .limited:
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                self.showPhotoPicker = true
            case .denied, .restricted:
                self.permissionMessage = PhotoPermissionManager.photoPermissionMessage(for: status)
                self.showPermissionAlert = true
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    // 레이아웃 확인용. 실제 날씨 API는 안 도므로 날씨 아이콘은 안 보일 수 있음.
    NavigationStack {
        ComposeView(model: .preview)
            .environmentObject(WeatherService())
            .environmentObject(SwiftDataManager())
            .environmentObject(FontManager())
    }
}
