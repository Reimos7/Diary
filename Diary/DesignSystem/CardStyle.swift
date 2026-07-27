//
//  CardStyle.swift
//  Diary
//
//  앱 전역에서 쓰는 "카드" 스타일을 하나의 모디파이어로 통일한다.
//
//  [원칙]
//  - 카드 표면/모서리/그림자를 매 화면 손으로 쓰지 않고 .appCard() 한 줄로 적용한다.
//  - AppColor·AppRadius·AppShadow 토큰을 조합해 일관성을 보장한다.
//

import SwiftUI

private struct AppCardModifier: ViewModifier {
    /// 카드 안쪽 여백. 기본은 md(16). 필요 시 호출부에서 조정.
    var padding: CGFloat = AppSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadow(
                color: AppShadow.color,
                radius: AppShadow.radius,
                x: AppShadow.x,
                y: AppShadow.y
            )
    }
}

extension View {
    /// 앱 표준 카드 스타일(표면색 + 둥근 모서리 + 은은한 그림자)을 적용한다.
    /// 사용: SomeView().appCard()  또는  .appCard(padding: AppSpacing.lg)
    func appCard(padding: CGFloat = AppSpacing.md) -> some View {
        modifier(AppCardModifier(padding: padding))
    }
}
