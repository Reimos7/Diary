//
//  BannerAdView.swift
//  Diary
//
//  AdMob 배너를 SwiftUI에서 쓰기 위한 래퍼.
//  - UIViewRepresentable로 GoogleMobileAds의 BannerView를 감싼다.
//  - 표준 배너(320x50, AdSizeBanner)를 사용한다.
//    · "large 적응형"은 높이를 최대 150pt까지 잡아 감성 일기 UI엔 과하고, 화면을 침범한다.
//    · 표준 50pt 배너는 footprint가 작고 예측 가능하며, 하단 고정 배치에 적합하다.
//

import SwiftUI
import GoogleMobileAds

/// 실제 AdMob 배너를 그리는 UIKit 뷰 래퍼.
private struct BannerContainer: UIViewRepresentable {
    /// 광고 단위 ID (테스트/실 ID는 AdConfig가 결정)
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)   // 표준 320x50
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.rootViewController()
        banner.load(AdConfig.makeRequest())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) { }

    /// 배너 표시에 필요한 최상위 뷰 컨트롤러(키 윈도우 기준).
    static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

/// 하단 고정용 표준 배너 뷰.
/// 사용: 캘린더/홈의 `.safeAreaInset(edge: .bottom) { BottomBannerAd() }`
struct BottomBannerAd: View {
    var body: some View {
        BannerContainer(adUnitID: AdConfig.bannerUnitID)
            .frame(maxWidth: .infinity)
            .frame(height: AdSizeBanner.size.height)   // 딱 50pt만 차지
    }
}
