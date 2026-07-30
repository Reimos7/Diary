//
//  PolaroidStyle.swift
//  Diary
//
//  사진을 "찢어진 종이 프레임(paper_frame 에셋)"으로 감싸는 재사용 모디파이어.
//  사진을 뒤에 깔고 그 위에 가운데가 뚫린 종이 프레임을 겹친다.
//  캘린더 Memories, 기록(리스트) 카드 등에서 공통 사용.
//

import SwiftUI

private struct PolaroidModifier: ViewModifier {
    /// 살짝 기울이는 각도(도). 0이면 똑바로.
    var rotation: Double
    /// 사진이 종이 프레임 안쪽에 들어가도록 줄이는 여백. 프레임 테두리가 사진 가장자리를 덮는다.
    var inset: CGFloat
    /// 사용할 프레임 에셋 이름 (캘린더용 paper_frame / 리스트용 photo_frame).
    var frameImage: String

    func body(content: Content) -> some View {
        content
            .padding(inset)
            .overlay(
                // 찢어진 종이 프레임을 사진 위에 겹침 (가운데 뚫려 사진이 비침)
                Image(frameImage)
                    .resizable()
                    .allowsHitTesting(false) // 프레임은 터치 통과 (사진 탭 유지)
            )
            // 프레임 자체 그림자는 제거됐으므로 은은한 그림자를 코드로 추가
            .shadow(color: AppShadow.color, radius: 5, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    /// 찢어진 종이 프레임 스타일을 적용한다.
    /// 사용: someImage.polaroid() 또는 .polaroid(rotation: -3, inset: 12, frameImage: "photo_frame")
    func polaroid(rotation: Double = 0, inset: CGFloat = 6, frameImage: String = "paper_frame") -> some View {
        modifier(PolaroidModifier(rotation: rotation, inset: inset, frameImage: frameImage))
    }
}

// MARK: - 찢어진 사진 (마스크 방식)

/// 사진 자체를 찢어진 종이 모양으로 잘라내고, 뒤에 흰 종이 테두리를 깐다.
/// (프레임을 위에 얹는 방식과 달리 사진 가장자리가 찢어진 모양으로 잘림 — 스티치 스타일)
private struct TornPhotoModifier: ViewModifier {
    var rotation: Double
    /// 크림 종이 테두리 색.
    private let paperColor = Color(hex: "#F7F3EA")

    func body(content: Content) -> some View {
        content
            // 사진을 찢어진 모양으로, 크림 테두리가 보이도록 살짝 작게 마스킹
            .mask(
                Image("torn_mask")
                    .resizable()
                    .scaleEffect(0.9)
            )
            // 뒤에 크림 종이(찢어진 모양)를 전체 크기로 깔아 종이 테두리를 만듦
            .background(
                Image("torn_mask")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(paperColor)
            )
            .shadow(color: AppShadow.color, radius: 6, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    /// 사진을 찢어진 종이 모양으로 잘라내는 스타일 (기록 리스트 카드용).
    func tornPhoto(rotation: Double = 0) -> some View {
        modifier(TornPhotoModifier(rotation: rotation))
    }
}
