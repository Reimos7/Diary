//
//  AppTheme.swift
//  Diary
//
//  색을 제외한 디자인 토큰(간격, 모서리, 그림자)을 정의
//
//  [원칙]
//  - 간격은 4의 배수로 통일한다. 리듬이 일정해야 "정돈된 감성"이 나온다.
//  - 둥근 모서리는 2단계로 고정한다(큰 카드 / 작은 요소).
//  - 그림자는 아주 은은하게. 진한 그림자는 감성 톤을 해친다.
//

import SwiftUI

/// 여백 단위. 예: .padding(AppSpacing.md)
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

/// 둥근 모서리 반경.
enum AppRadius {
    /// 카드 등 큰 요소.
    static let card: CGFloat = 20
    /// 버튼·작은 요소.
    static let small: CGFloat = 12
}

/// 그림자 프리셋.
enum AppShadow {
    /// 카드용 은은한 그림자.
    static let color = Color.black.opacity(0.06)
    static let radius: CGFloat = 8
    static let x: CGFloat = 0
    static let y: CGFloat = 2
}
