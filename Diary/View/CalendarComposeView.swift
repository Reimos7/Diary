//
//  FSCalenderComposeView.swift
//  Diary
//
//  Created by Reimos on 2/19/25.
//  새 디자인: ComposeView와 동일한 틀. 단, 캘린더 작성은 날씨를 기록하지 않으므로 날씨 블록은 없음.
//  틀: [사진] → 날짜(우측) → 가로 구분선 → 왼쪽 세로선 [가운데 본문(입력)]
//

import SwiftUI
import PhotosUI

// MARK: - 사용자가 캘린더에서 날짜를 선택하면 실행
struct CalendarComposeView: View {
    @State private var content: String = ""
    @State private var showToast: Bool = false
    @State private var isLongPressedPhoto: Bool = false
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var imagePath: [String]? = nil
    @State private var isPreSentedError: Bool = false

    // 사진 권한 관련 상태
    @State private var showPhotoPicker: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""

    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    @FocusState var focused: Bool

    // 사진 보유 여부
    private var hasPhotos: Bool { !selectedImages.isEmpty }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // 1) 사진 블록 — 선택했을 때만 (전체 너비 히어로)
                        if hasPhotos {
                            photoSection
                        }

                        // 2) 날짜 (캘린더에서 고른 날짜, 우측 정렬)
                        dateSection

                        // 3) 가로 구분선
                        Rectangle()
                            .fill(AppColor.divider)
                            .frame(height: 1)

                        // 4) 왼쪽 세로선 + 가운데 본문 입력 (날씨 블록 없음)
                        contentSection(fillHeight: fillHeight(for: geo.size.height))
                    }
                }
                .background(AppColor.background.ignoresSafeArea())
                .onChange(of: content) { _, _ in
                    withAnimation { proxy.scrollTo("textEditorScroll", anchor: .bottom) }
                }
                .navigationBarBackButtonHidden()
                .background(NavigationControllerWrapper())
                .toolbar { toolbarContent }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.focused = true
                    }
                    AnalyticsManager.log(.composeStarted(entryPoint: "calendar"))
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

    // MARK: - 사진 블록 (전체 너비 히어로 + 길게 눌러 휴지통)

    private var photoSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(selectedImages, id: \.self) { image in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipped()
                        .colorMultiply(isLongPressedPhoto ? .gray : .white)
                        .onTapGesture {
                            selectedImageForFullscreen = IdentifiableImage(image: image)
                        }
                        .onLongPressGesture {
                            isLongPressedPhoto.toggle()
                        }

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
            Text(DateFormatter.dateFormatter.string(from: selectedDate))
                .customFont(size: 17)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - 본문 영역 (왼쪽 세로선 + 가운데 입력)

    private func contentSection(fillHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppColor.divider)
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            VStack(spacing: AppSpacing.lg) {
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
            .padding(.top, AppSpacing.lg)
        }
        .frame(minHeight: fillHeight)
        .padding(.leading, AppSpacing.md)
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

    // MARK: - 저장 (기존 로직 유지: 선택한 날짜로 저장, 날씨 없음)

    private func saveDiary() {
        Task {
            var savedFileNames: [String] = []
            for image in selectedImages {
                if let fileName = FileManagerSet.saveImageToFileManager(image: image) {
                    savedFileNames.append(fileName)
                }
            }
            imagePath = savedFileNames.isEmpty ? nil : savedFileNames

            manager.addDiaryData(content: content, date: selectedDate, imagePath: imagePath)

            self.focused = false
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showToast = false
                dismiss()
                // 저장 완료(작성 화면 닫힘) 직후 = 자연스러운 정지점. 조건 충족 시 전면 광고.
                InterstitialAdManager.shared.notifyDiarySaved()
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
    NavigationStack {
        CalendarComposeView(selectedDate: .constant(Date()))
            .environmentObject(SwiftDataManager())
            .environmentObject(FontManager())
    }
}
