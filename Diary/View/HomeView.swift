//
//  HomeView.swift
//  Diary
//
//  새 디자인의 홈 화면 ("일기책 표지" 컨셉).
//  구성: 오늘 날짜 + 기록 일수 + 날씨 카드 + 표지 사진 + 오늘 일기 쓰기 버튼.
//
//  [설계 메모]
//  - 색/간격/카드는 전부 디자인 시스템(AppColor·AppSpacing·.appCard) 사용.
//  - 표지 사진 파일명은 @AppStorage에 저장해 앱 재실행 후에도 유지된다.
//  - 탭바 연결(설정/작성/기록 이동)은 이후 단계에서 붙인다. 지금은 화면 UI에 집중.
//

import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var service: WeatherService
    @EnvironmentObject var manager: SwiftDataManager

    // 표지 사진 파일명(FileManager에 저장된 이름). 없으면 빈 문자열 → 기본 그라데이션 표시.
    @AppStorage("coverImageFileName") private var coverImageFileName: String = ""

    // 표지 변경용 PhotosPicker 상태
    @State private var coverPickerItem: PhotosPickerItem?
    // 로드된 표지 이미지 (파일명으로부터 불러온 결과)
    @State private var coverImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection
                weatherCard
                coverSection
                writeButton
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.background.ignoresSafeArea())
        .onAppear(perform: loadCoverImage)
        // 사용자가 표지 사진을 새로 고르면 저장 후 화면 갱신
        .onChange(of: coverPickerItem) { _, newItem in
            Task { await handlePickedCover(newItem) }
        }
    }

    // MARK: - 헤더 (날짜 + 기록 일수)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // 오늘 날짜 — 큰 감성 타이포
            Text(DateFormatter.dateFormatter.string(from: Date()))
                .customFont(size: 26)
                .foregroundStyle(AppColor.textPrimary)

            // 기록 일수 — 총 일기 개수 기반 (성취감 요소)
            Text("📖 \(streakCount)일째 기록 중")
                .customFont(size: 15)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 지금까지 작성한 총 일기 개수.
    private var streakCount: Int {
        manager.diaryEntries.count
    }

    // MARK: - 날씨 카드

    private var weatherCard: some View {
        HStack(spacing: AppSpacing.md) {
            if service.showLocationDeniedWeatherView {
                // 위치 권한 거부 시 안내
                Text("위치 권한을 허용하면\n날씨를 기록할 수 있어요")
                    .customFont(size: 14)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let weather = service.currentWeather {
                // 왼쪽: 지역 + 온도
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(service.currentLocation ?? "현재 위치")
                        .customFont(size: 15)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(weather.temperature)
                        .customFont(size: 34)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("최고 \(weather.maxTemperature) · 최저 \(weather.minTemperature)")
                        .customFont(size: 12)
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                // 오른쪽: 날씨 아이콘
                Image(systemName: weather.icon)
                    .symbolRenderingMode(.multicolor)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
            } else {
                // 로딩 중
                Text("날씨를 불러오는 중...")
                    .customFont(size: 14)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .appCard(padding: AppSpacing.lg)
    }

    // MARK: - 표지 사진

    private var coverSection: some View {
        ZStack(alignment: .bottomTrailing) {
            // 표지 이미지가 있으면 사진, 없으면 은은한 기본 그라데이션
            if let coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [AppColor.accentSoft, AppColor.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Text("나만의 표지를 더해보세요")
                        .customFont(size: 15)
                        .foregroundStyle(AppColor.textSecondary)
                )
            }

            // 표지 변경 버튼
            PhotosPicker(selection: $coverPickerItem, matching: .images) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "pencil")
                    Text("표지 변경")
                        .customFont(size: 13)
                }
                .foregroundStyle(AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColor.surface.opacity(0.9))
                .clipShape(Capsule())
                .padding(AppSpacing.md)
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
    }

    // MARK: - 오늘 일기 쓰기 버튼

    private var writeButton: some View {
        // 실제 화면 이동은 이후 탭바/네비게이션 단계에서 연결한다.
        Button {
            // TODO: 작성 화면으로 이동 (탭바 연결 단계에서 처리)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "square.and.pencil")
                Text("오늘 일기 쓰기")
                    .customFont(size: 17)
            }
            .foregroundStyle(AppColor.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
        }
    }

    // MARK: - 표지 이미지 로직

    /// 저장된 파일명으로 표지 이미지를 불러온다.
    private func loadCoverImage() {
        guard !coverImageFileName.isEmpty else {
            coverImage = nil
            return
        }
        coverImage = FileManagerSet.loadImageFromFileManager(fileName: coverImageFileName)
    }

    /// PhotosPicker로 고른 사진을 파일로 저장하고 표지로 반영한다.
    private func handlePickedCover(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        // 이전 표지 파일이 있으면 정리(불필요한 파일 누적 방지)
        if !coverImageFileName.isEmpty {
            FileManagerSet.deleteImageFromFileManager(fileName: coverImageFileName)
        }

        // 새 표지 저장 후 파일명 기록
        if let fileName = FileManagerSet.saveImageToFileManager(image: image) {
            coverImageFileName = fileName
            coverImage = image
        }
    }
}

#Preview {
    // Preview용 의존성 주입. 실제 날씨 API는 안 도므로 날씨 카드는 로딩 상태로 보일 수 있음.
    // .customFont가 FontManager를 EnvironmentObject로 요구하므로 반드시 함께 주입한다.
    HomeView()
        .environmentObject(WeatherService())
        .environmentObject(SwiftDataManager())
        .environmentObject(FontManager())
}
