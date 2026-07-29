//
//  AppColor.swift
//  Diary
//
//  앱 전체 색 팔레트를 한 곳에서 정의 (
//
//  [원칙]
//  - 화면 코드에서는 hex를 직접 쓰지 않고 AppColor.xxx 만 사용
//  - 색을 바꿀 일이 생기면 이 파일 한 곳만 수정하면 전체에 반영
//  - 이름은 "무슨 색"이 아니라 "어디에 쓰는지(용도)"로 짓는다.
//    → 나중에 다크모드를 추가해도 이름은 그대로 두고 값만 분기하면 된다
//

import SwiftUI

enum AppColor {
    // MARK: - 기본
    /// 앱 배경 (웜 아이보리). 순백 대신 따뜻한 크림톤.
    static let background = Color(hex: "#FAF7F1")
    /// 카드 표면. 배경보다 살짝 밝고 따뜻한 톤.
    static let surface = Color(hex: "#FFFDF9")

    // MARK: - 텍스트
    /// 본문·제목 (딥 웜그레이). 순검정 대신 부드러운 다크.
    static let textPrimary = Color(hex: "#3A3632")
    /// 보조 텍스트·날짜 부제 등.
    static let textSecondary = Color(hex: "#9B948C")

    // MARK: - 포인트
    /// 앱의 시그니처 포인트 색 (더스티 블루). 절제해서 사용.
    static let accent = Color(hex: "#8FA9C0")
    /// 오늘 표시·선택 배경 등 은은한 강조 (연한 블루).
    static let accentSoft = Color(hex: "#DCE5EE")

    // MARK: - 캘린더 요일
    /// 일요일 (뮤트 로즈).
    static let sunday = Color(hex: "#C98A8A")
    /// 토요일 (더스티 블루, 포인트와 동일 계열).
    static let saturday = Color(hex: "#8FA9C0")

    // MARK: - 기타
    /// 은은한 구분선. 배경과 자연스럽게 구분되도록 살짝 진한 웜그레이.
    static let divider = Color(hex: "#D9CFC0")

    /// 캘린더에서 "일기가 있는 날"에 칠하는 파스텔 색 모음. 날짜별로 다르게(랜덤) 사용.
    static let calendarPastels: [Color] = [
        Color(hex: "#D8CCF0"), // 라벤더
        Color(hex: "#FFD9C0"), // 피치
        Color(hex: "#C4E4D6"), // 민트
        Color(hex: "#F2CCCC"), // 로즈
        Color(hex: "#C9DCF0")  // 스카이
    ]
}
