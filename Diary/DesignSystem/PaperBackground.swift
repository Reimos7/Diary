//
//  PaperBackground.swift
//  Diary
//
//  은은한 종이 질감 배경을 적용하는 재사용 모디파이어.
//  paper_texture 에셋(코드로 생성한 미세 그레인 크림 텍스처)을 화면 배경으로 깐다.
//

import SwiftUI

extension View {
    /// 종이 질감 배경을 화면 전체에 적용한다.
    func paperBackground() -> some View {
        background(
            Image("paper_texture")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        )
    }
}
