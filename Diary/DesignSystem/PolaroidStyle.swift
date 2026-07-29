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

    func body(content: Content) -> some View {
        content
            .padding(inset)
            .overlay(
                // 찢어진 종이 프레임을 사진 위에 겹침 (가운데 뚫려 사진이 비침)
                Image("paper_frame")
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
    /// 사용: someImage.polaroid() 또는 .polaroid(rotation: -3, inset: 6)
    func polaroid(rotation: Double = 0, inset: CGFloat = 6) -> some View {
        modifier(PolaroidModifier(rotation: rotation, inset: inset))
    }
}
