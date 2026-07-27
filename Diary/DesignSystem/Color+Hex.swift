//
//  Color+Hex.swift
//  Diary
//
//  SwiftUI Color를 "#RRGGBB" 16진수 문자열로 만들 수 있게 해주는 헬퍼.
//  디자인 시스템에서 팔레트를 hex로 정의하기 위해 필요하다.
//

import SwiftUI

extension Color {
    /// "#FAF7F1" 또는 "FAF7F1" 형태의 hex 문자열로 Color를 생성한다.
    /// 잘못된 값이면 투명색(.clear)을 반환한다(앱이 죽지 않도록 방어).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&rgb), cleaned.count == 6 else {
            self = .clear
            return
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
