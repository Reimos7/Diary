import SwiftUI

struct DetailView: View {
    @State private var screenshotImage: UIImage? = nil
    @State private var screenshotShareAlert: Bool = false
    // 스크린샷이 저장되면 사용자에게 Toast 메시지로 보여주기
    @State private var showToast: Bool = false
    @State private var showEditComposeView: Bool = false
    @State private var showDeleteAlert: Bool = false
    // 클릭한 이미지 풀 스크린
    @State private var selectedImageForFullscreen: IdentifiableImage? = nil

    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss

    let data: Diary

    // 사진 보유 여부. 이 값으로 "사진 블록"만 켜고 끈다. 나머지 레이아웃은 동일.
    private var hasPhotos: Bool {
        !(data.imagePath?.isEmpty ?? true)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    AppColor.background.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 0) {
                            // 1) 사진 블록 — 있을 때만. 없으면 아래 내용이 자연히 위로 당겨진다.
                            if hasPhotos {
                                photoSection
                            }

                            // 2) 날짜 (우측 정렬)
                            dateSection

                            // 3) 가로 구분선 (원래대로 전체 너비)
                            Rectangle()
                                .fill(AppColor.divider)
                                .frame(height: 1)

                            // 4) 세로 구분선으로 감싼 본문 영역 (날씨 + 설명 + 본문)
                            contentSection(fillHeight: fillHeight(for: geo.size.height))
                        }
                    }
                    // 사진이 있으면 사진이 네비게이션 바 밑까지 꽉 차게 (상단 안전영역 무시)
                    .ignoresSafeArea(edges: hasPhotos ? .top : [])

                    // 캡쳐 저장 완료 토스트
                    if showToast {
                        Text("스크린샷 앨범 저장 성공")
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
            .fullScreenCover(item: $selectedImageForFullscreen) { fullScreenImage in
                FullscreenImageView(image: fullScreenImage.image)
            }
            .navigationBarBackButtonHidden()
            .background(NavigationControllerWrapper())
            .navigationBarTitleDisplayMode(.inline)
            // 네비게이션 바 배경 투명 → 사진이 그 아래로 비쳐 상단이 꽉 참
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar { toolbarContent }
            .alert("일기를 앨범에 저장하시겠습니까?", isPresented: $screenshotShareAlert) {
                Button("확인") {
                    if let screenshot = screenshotImage {
                        saveCaptureImageToAlbum(screenshot)
                        showToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showToast = false
                        }
                        shareScreenShot(screenshot)
                        // Analytics: 공유/캡처 이벤트(바이럴 지표)
                        AnalyticsManager.log(.diaryShared(type: "image"))
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("확인을 통해 공유를 시작합니다")
            }
            .alert("삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button(role: .destructive) {
                    manager.deleteDiaryData(entry: data)
                    dismiss()
                } label: {
                    Text("삭제")
                }
            } message: {
                Text("일기를 삭제할까요?")
            }
            .fullScreenCover(isPresented: $showEditComposeView) {
                EditComposeView(data: data)
            }
        }
        .trackScreen("Detail")
    }

    // MARK: - 사진 블록 (있을 때만)

    private var photoSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if let paths = data.imagePath {
                ForEach(paths, id: \.self) { fileName in
                    if let image = FileManagerSet.loadImageFromFileManager(fileName: fileName) {
                        photoImage(image)
                    }
                }
            }
        }
    }

    /// 사진 방향에 따라 다르게 표시.
    /// - 가로 사진: 비율 유지(scaledToFit) → 잘림 없이 낮고 넓게.
    /// - 세로 사진: 채우고 크롭(scaledToFill + 고정 높이) → 레터박스 없이 꽉 차게.
    @ViewBuilder
    private func photoImage(_ image: UIImage) -> some View {
        let isLandscape = image.size.width >= image.size.height
        Group {
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
        // 하단을 크림색으로 부드럽게 페이드 → 아래 내용과 자연스럽게 이어짐
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, AppColor.background],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 90)
                .allowsHitTesting(false)
        }
        .onTapGesture {
            selectedImageForFullscreen = IdentifiableImage(image: image)
        }
    }

    // MARK: - 날짜 (우측 정렬)

    private var dateSection: some View {
        HStack {
            Spacer()
            Text(DateFormatter.dateFormatter.string(from: data.date))
                .customFont(size: 17)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - 본문 영역 (세로 구분선으로 감싼 날씨 + 설명 + 본문)

    private func contentSection(fillHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            // 왼쪽 세로선만.
            // 위쪽은 공책 여백선처럼 살짝 올라가게(offset -30), 대신 높이를 30 더 늘려 하단까지 이어지게 함.
            Rectangle()
                .fill(AppColor.divider)
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .padding(.bottom, -30)
                .offset(y: -30)

            VStack(spacing: AppSpacing.md) {
                // 날씨 아이콘 + 설명 (우측 정렬)
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    weatherIcon(size: 60)

                    // 날씨 설명 (B): 저장된 날씨 데이터를 한글 설명으로 표시
                    if !weatherDescription.isEmpty {
                        Text(weatherDescription)
                            .customFont(size: 14)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                // 본문 (가운데 정렬, 넉넉한 줄간격)
                Text(data.content)
                    .customFont(size: 18)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
        }
        .frame(minHeight: fillHeight)
        // 왼쪽 세로선을 화면 끝에서 살짝 안쪽으로 → 공책 여백선처럼 보이게
        .padding(.leading, AppSpacing.md)
    }

    /// 세로선이 아래까지 채워지도록 본문 영역의 최소 높이를 계산.
    /// 사진이 있으면 위 공간을 그만큼 빼서 스크롤과 자연스럽게 맞춘다.
    private func fillHeight(for totalHeight: CGFloat) -> CGFloat {
        let reserved: CGFloat = hasPhotos ? 400 : 140
        return max(totalHeight - reserved, 240)
    }

    // MARK: - 날씨 아이콘 (공통)

    @ViewBuilder
    private func weatherIcon(size: CGFloat) -> some View {
        if data.currentWeatherImage != nil {
            WeatherIconView(symbol: data.currentWeatherImage, size: size)
        }
    }

    /// 저장된 날씨 심볼 이름을 한글 설명으로 변환한다.
    /// (일기에는 SF Symbol 이름만 저장되므로 키워드로 판별)
    private var weatherDescription: String {
        guard let s = data.currentWeatherImage else { return "" }
        switch true {
        case s.contains("snow"), s.contains("snowflake"), s.contains("sleet"), s.contains("hail"):
            return "눈"
        case s.contains("bolt"):
            return "천둥번개"
        case s.contains("rain"), s.contains("drizzle"), s.contains("heavyrain"):
            return "비"
        case s.contains("fog"), s.contains("haze"), s.contains("smoke"), s.contains("dust"):
            return "안개"
        case s.contains("wind"), s.contains("hurricane"), s.contains("tropicalstorm"):
            return "바람"
        case s.contains("cloud.sun"), s.contains("cloud.moon"):
            return "구름 조금"
        case s.contains("cloud"):
            return "흐림"
        case s.contains("sun.max"), s.contains("moon.stars"):
            return "맑음"
        default:
            return ""
        }
    }

    // MARK: - 툴바

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
                captureScreenShot()
                screenshotShareAlert = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(AppColor.textPrimary)
            }
            Menu {
                Button(role: .destructive) { showDeleteAlert = true } label: { Text("삭제") }
                Button { showEditComposeView = true } label: { Text("편집") }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
    }

    // MARK: - 캡처/공유 (기존 기능 유지)

    private func captureScreenShot() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let screenshot = window.rootViewController?.view.changeUIImage() {
            self.screenshotImage = screenshot
        }
    }

    private func shareScreenShot(_ screenshot: UIImage) {
        let shareText = "일기 캡쳐본"
        let activityViewController = UIActivityViewController(activityItems: [shareText, screenshot], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

#Preview("사진 없음") {
    // 사진이 없는 경우 = 사진 블록만 빠지고 나머지는 그대로 위로 당겨진 레이아웃.
    DetailView(data: Diary(
        content: "오랜만에 친구들과 바다를 보러 강릉에 다녀왔다.",
        date: Date(),
        imagePath: nil,
        currentWeatherImage: "cloud.sun.fill"
    ))
    .environmentObject(SwiftDataManager())
    .environmentObject(FontManager())
}
