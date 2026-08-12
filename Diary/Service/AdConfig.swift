//
//  AdConfig.swift
//  Diary
//
//  AdMob 광고 단위 ID를 한 곳에서 관리한다.
//
//  [핵심 원칙]
//  - 개발/디버그 중에는 반드시 "구글 공식 테스트 광고 ID"를 쓴다.
//    실제 광고 ID로 반복 테스트하면 '무효 트래픽'으로 간주되어 AdMob 계정이 정지될 수 있다.
//  - DEBUG 빌드 → 테스트 ID, RELEASE 빌드 → 실제 ID 로 자동 분기한다.
//  - 실제 배포 직전에 아래 real... 값만 발급받은 실 ID로 교체하면 된다. (지금은 비워둔 placeholder)
//

import Foundation
import GoogleMobileAds

enum AdConfig {

    // ATT(추적 동의)를 구현하지 않으므로, 모든 광고 요청을 "비개인화(NPA)"로 강제한다.
    // 이렇게 하면 사용자 추적 없이 광고가 나가고, App Store 개인정보 라벨의 "추적"을 전부 "아니오"로 둘 수 있다.
    // (앱이 커지면 ATT + 개인화 광고로 전환 예정)
    static func makeRequest() -> Request {
        let request = Request()
        let extras = Extras()
        extras.additionalParameters = ["npa": "1"]   // npa=1 → 비개인화 광고
        request.register(extras)
        return request
    }

    // 구글이 공개한 "테스트 전용" 광고 단위 ID (누구나 사용 가능, 항상 테스트 광고만 나옴)
    private enum Test {
        static let banner = "ca-app-pub-3940256099942544/2934735716"
        static let interstitial = "ca-app-pub-3940256099942544/4411468910"
        static let native = "ca-app-pub-3940256099942544/3986624511"
    }

    // 실제 광고 단위 ID (AdMob 콘솔 발급값). RELEASE 빌드에서만 사용된다.
    private enum Real {
        static let banner = "ca-app-pub-4251482602787219/5005836084"
        static let interstitial = "ca-app-pub-4251482602787219/7816546266"
        static let native = "ca-app-pub-4251482602787219/1179251650"
    }

    // DEBUG에서는 테스트 ID, RELEASE에서는 실 ID(비어 있으면 테스트 ID로 안전 폴백).
    static var bannerUnitID: String {
        #if DEBUG
        return Test.banner
        #else
        return Real.banner.isEmpty ? Test.banner : Real.banner
        #endif
    }

    static var interstitialUnitID: String {
        #if DEBUG
        return Test.interstitial
        #else
        return Real.interstitial.isEmpty ? Test.interstitial : Real.interstitial
        #endif
    }

    static var nativeUnitID: String {
        #if DEBUG
        return Test.native
        #else
        return Real.native.isEmpty ? Test.native : Real.native
        #endif
    }
}
