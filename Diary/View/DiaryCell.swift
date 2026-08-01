//
//  DiaryCell.swift
//  Diary
//
//  Created by Reimos on 2/21/25.
//  새 디자인: 흰 카드 + 종이 프레임(폴라로이드) 사진이 좌/우 번갈아 겹쳐진 피드 셀.
//  사진 없는 일기는 카드만 표시.
//

import SwiftUI

struct DiaryCell: View {
    let data: Diary
    /// 리스트에서의 순번. 홀짝에 따라 사진을 좌/우로 번갈아 배치하고 기울임 각도를 다르게 한다.
    var index: Int = 0
    /// Preview 전용 샘플 이미지(실제 파일 대신). 앱 실행 시에는 사용하지 않는다.
    var previewImage: UIImage? = nil

    // 사진 보유 여부
    private var hasPhoto: Bool { previewImage != nil || !(data.imagePath?.isEmpty ?? true) }
    // 사진을 왼쪽에 둘지 (짝수 = 왼쪽)
    private var photoOnLeft: Bool { index % 2 == 0 }
    // 살짝 기울임 각도 (순번 기반으로 다르게, 손으로 붙인 느낌)
    private var tilt: Double {
        let angles: [Double] = [-4, 3, -3, 4]
        return angles[index % angles.count]
    }

    // 카드가 사진 아래로 파고드는 정도(겹침). 사진 바깥쪽엔 카드가 안 보이게 한다.
    private let overlap: CGFloat = 45

    var body: some View {
        Group {
            if hasPhoto {
                // 사진이 있으면: 사진 + 카드를 겹쳐 배치 (사진이 카드 끝을 덮음)
                HStack(spacing: -overlap) {
                    if photoOnLeft {
                        photoView.zIndex(1)
                        card(photoSide: .leading)
                    } else {
                        card(photoSide: .trailing)
                        photoView.zIndex(1)
                    }
                }
            } else {
                // 사진 없으면: 카드만 (전체 너비)
                card(photoSide: [])
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }

    /// 흰 카드. photoSide에 사진이 겹치는 쪽 여백을 더 줘서 텍스트가 사진에 안 가리게 한다.
    private func card(photoSide: Edge.Set) -> some View {
        cardContent
            .padding(AppSpacing.md)
            .padding(photoSide, overlap)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: AppShadow.color, radius: AppShadow.radius, x: AppShadow.x, y: AppShadow.y)
            )
    }

    // MARK: - 카드 내용 (날짜 + 날씨 + 본문)

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(DateFormatter.dateFormatter.string(from: data.date))
                .customFont(size: 18)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 날씨 (아이콘 + 한글 설명)
            if let symbol = data.currentWeatherImage {
                HStack(spacing: AppSpacing.xs) {
                    WeatherIconView(symbol: symbol, size: 42)
                    if !weatherDescription.isEmpty {
                        Text(weatherDescription)
                            .customFont(size: 13)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }

            // 본문 (2줄 요약)
            Text(data.content)
                .customFont(size: 14)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - 사진 (종이 프레임)

    @ViewBuilder
    private var photoView: some View {
        // Preview 샘플 이미지가 있으면 그것을, 없으면 실제 파일에서 로드
        let uiImage: UIImage? = previewImage
            ?? data.imagePath?.first.flatMap { FileManagerSet.loadImageFromFileManager(fileName: $0) }

        if let image = uiImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipped()
                .polaroid(rotation: tilt, inset: 11, frameImage: "photo_frame")
        }
    }

    // MARK: - 날씨 심볼 → 한글 설명 (상세 화면과 동일 규칙)

    private var weatherDescription: String {
        guard let s = data.currentWeatherImage else { return "" }
        switch true {
        case s.contains("snow"), s.contains("snowflake"), s.contains("sleet"), s.contains("hail"):
            return "눈"
        case s.contains("bolt"): return "천둥번개"
        case s.contains("rain"), s.contains("drizzle"), s.contains("heavyrain"): return "비"
        case s.contains("fog"), s.contains("haze"), s.contains("smoke"), s.contains("dust"): return "안개"
        case s.contains("wind"), s.contains("hurricane"), s.contains("tropicalstorm"): return "바람"
        case s.contains("cloud.sun"), s.contains("cloud.moon"): return "구름 조금"
        case s.contains("cloud"): return "흐림"
        case s.contains("sun.max"), s.contains("moon.stars"): return "맑음"
        default: return ""
        }
    }
}

#Preview {
    // Preview용 단색 샘플 이미지 (실제 사진 대신 폴라로이드 레이아웃 확인)
    func sample(_ color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200)).image { ctx in
            color.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
        }
    }

    return ScrollView {
        VStack(spacing: AppSpacing.md) {
            DiaryCell(data: Diary(content: "오랜만에 친구들과 바다를 보러 강릉에 다녀왔다.", date: Date(), currentWeatherImage: "cloud.sun.fill"),
                      index: 0, previewImage: sample(.systemTeal))
            DiaryCell(data: Diary(content: "우연히 들어간 가게에 예쁜 피아노가 있었다. 인테리어도 정말 예뻤다.", date: Date(), currentWeatherImage: "sun.max.fill"),
                      index: 1, previewImage: sample(.systemOrange))
            DiaryCell(data: Diary(content: "사진 없는 날의 일기. 조용히 하루를 마무리했다.", date: Date(), currentWeatherImage: "cloud.fill"),
                      index: 2)
        }
        .padding(AppSpacing.md)
    }
    .paperBackground()
    .environmentObject(FontManager())
}
