//
//  EditComposeView.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//  새 디자인: 상세/작성 화면과 동일한 틀. 기존 일기를 불러와 편집.
//  틀: [사진] → 날짜(우측) → 가로 구분선 → 왼쪽 세로선 [우측 날씨 + 가운데 본문(입력)]
//  편집 특성상 사진 삭제는 실제 파일 + SwiftData에서도 즉시 삭제된다.
//

import SwiftUI
import PhotosUI

struct EditComposeView: View {
    @State private var content: String = ""
    @State private var showDismissAlert: Bool = false
    @State private var showToast: Bool = false
    @State private var isLongPressedPhoto: Bool = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    @State private var imagePath: [String] = []

    // 사진 권한
    @State private var showPhotoPicker: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    @FocusState var focused: Bool

    let data: Diary?

    // 편집 대상 일기가 가진 사진 파일명 목록
    private var photoPaths: [String] { data?.imagePath ?? [] }
    private var hasPhotos: Bool { !photoPaths.isEmpty }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // 1) 사진 블록 (기존 일기의 사진, 전체 너비 히어로)
                            if hasPhotos {
                                photoSection
                            }

                            // 2) 날짜 (기존 일기 날짜, 우측 정렬)
                            dateSection

                            // 3) 가로 구분선
                            Rectangle()
                                .fill(AppColor.divider)
                                .frame(height: 1)

                            // 4) 왼쪽 세로선 + [우측 날씨 + 가운데 본문 입력]
                            contentSection(fillHeight: fillHeight(for: geo.size.height))
                        }
                    }
                    .background(AppColor.background.ignoresSafeArea())
                    // 사진이 있으면 네비게이션 바 밑까지 꽉 차게
                    .ignoresSafeArea(edges: hasPhotos ? .top : [])
                    .onChange(of: content) { _, _ in
                        withAnimation { proxy.scrollTo("textEditorScroll", anchor: .bottom) }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.focused = true
                        }
                        // 기존 일기 내용 불러오기
                        if let existing = data?.content {
                            content = existing
                        }
                    }
                    .customKeyboardToolbar(focused: $focused, content: $content)
                    .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItems, maxSelectionCount: 1, matching: .images)
                    .onChange(of: selectedItems) { _, newValue in
                        Task {
                            await updateSelectedImage(newItems: newValue)
                        }
                        isLongPressedPhoto = false
                    }
                    .alert(permissionMessage, isPresented: $showPermissionAlert) {
                        Button("취소") {}
                        if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .denied ||
                            PHPhotoLibrary.authorizationStatus(for: .readWrite) == .restricted {
                            Button("설정") { PhotoPermissionManager.openPhotoSetting() }
                        }
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbar { toolbarContent }
                    .alert("글 작성을 그만하시나요?", isPresented: $showDismissAlert) {
                        Button("나가기", role: .destructive) { dismiss() }
                        Button("계속 작성", role: .cancel) { showDismissAlert = false }
                    } message: {
                        Text("작성한 글이 저장되지 않습니다!")
                    }
                    .overlay(alignment: .bottom) {
                        if showToast {
                            Text("일기를 수정했어요!")
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
    }

    // MARK: - 사진 블록 (전체 너비 히어로 + 길게 눌러 휴지통, 삭제 시 SwiftData 반영)

    private var photoSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(photoPaths, id: \.self) { path in
                if let image = FileManagerSet.loadImageFromFileManager(fileName: path) {
                    ZStack {
                        // 사진 방향에 따라 다르게 (상세 화면과 동일): 가로=fit, 세로=fill 크롭
                        photoImage(image)
                            // 하단을 크림색으로 부드럽게 페이드
                            .overlay(alignment: .bottom) {
                                LinearGradient(colors: [.clear, AppColor.background],
                                               startPoint: .top, endPoint: .bottom)
                                    .frame(height: 90)
                                    .allowsHitTesting(false)
                            }
                            .colorMultiply(isLongPressedPhoto ? .gray : .white)
                            .onTapGesture {
                                selectedImageForFullscreen = IdentifiableImage(image: image)
                            }
                            .onLongPressGesture {
                                isLongPressedPhoto.toggle()
                            }

                        if isLongPressedPhoto {
                            Button {
                                deletePhoto(path: path)
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
        .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
            FullscreenImageView(image: fullScreenImage.image)
        }
    }

    /// 사진 방향에 따라 다르게 (상세 화면과 동일). 가로=fit(전체), 세로=fill 크롭(꽉 차게).
    @ViewBuilder
    private func photoImage(_ image: UIImage) -> some View {
        let isLandscape = image.size.width >= image.size.height
        if isLandscape {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 420)
        } else {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 440)
                .clipped()
        }
    }

    /// 편집 화면에서 사진 삭제: 파일 삭제 + SwiftData의 imagePath에서 제거 후 저장.
    private func deletePhoto(path: String) {
        FileManagerSet.deleteImageFromFileManager(fileName: path)
        if let diary = data, var paths = diary.imagePath {
            paths.removeAll { $0 == path }
            diary.imagePath = paths.isEmpty ? nil : paths
            manager.saveContext()
        }
    }

    // MARK: - 날짜 (우측 정렬)

    private var dateSection: some View {
        HStack {
            Spacer()
            Text(DateFormatter.dateFormatter.string(from: data?.date ?? Date()))
                .customFont(size: 17)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - 본문 영역 (왼쪽 세로선 + 우측 날씨 + 가운데 입력)

    private func contentSection(fillHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.divider)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            VStack(spacing: AppSpacing.md) {
                // 날씨 (기존 일기의 날씨, 우측 정렬)
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
        .padding(.leading, AppSpacing.md)
    }

    // MARK: - 날씨 블록 (우측 정렬)

    @ViewBuilder
    private var weatherBlock: some View {
        if let symbol = data?.currentWeatherImage {
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                WeatherIconView(symbol: symbol, size: 60)
                if let desc = WeatherIconView.description(for: symbol) {
                    Text(desc)
                        .customFont(size: 14)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private func fillHeight(for totalHeight: CGFloat) -> CGFloat {
        let reserved: CGFloat = hasPhotos ? 400 : 140
        return max(totalHeight - reserved, 240)
    }

    // MARK: - 툴바 (기존 기능 유지)

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showDismissAlert = true
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(AppColor.textPrimary)
            }
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
                saveEdit()
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

    // MARK: - 저장 (기존 로직: 내용 업데이트)

    private func saveEdit() {
        guard let data = data else { return }
        manager.updateDiaryData(entry: data, newContent: content)
        self.focused = false
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showToast = false
            dismiss()
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

    // 새 이미지를 선택하면 기존 이미지를 삭제하고 새 이미지를 저장 (기존 로직 유지)
    private func updateSelectedImage(newItems: [PhotosPickerItem]) async {
        guard let data = data else { return }

        // 기존 이미지 파일 삭제
        if let paths = data.imagePath {
            for path in paths {
                FileManagerSet.deleteImageFromFileManager(fileName: path)
            }
        }
        data.imagePath = nil
        try? manager.saveContext()

        imagePath.removeAll()
        selectedItems.removeAll()

        // 새 이미지 저장
        for item in newItems {
            if let loaded = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: loaded) {
                if let savedPath = FileManagerSet.saveImageToFileManager(image: image) {
                    imagePath.append(savedPath)
                }
                DispatchQueue.main.async {
                    selectedImages.append(image)
                }
            }
        }
        data.imagePath = imagePath.isEmpty ? nil : imagePath
        try? manager.saveContext()
    }
}
