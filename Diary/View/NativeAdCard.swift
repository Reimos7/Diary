//
//  NativeAdCard.swift
//  Diary
//
//  기록(List) 피드에 자연스럽게 섞이는 네이티브 광고 카드.
//  - AdMob NativeAd를 로드하고, 앱의 흰 카드 + 소프트 섀도우 디자인으로 직접 스타일링한다.
//  - AdMob 정책상 "광고" 표기를 반드시 노출한다.
//  - 배너보다 eCPM이 높고, 폴라로이드 피드와 이질감이 적다.
//

import SwiftUI
import GoogleMobileAds

// MARK: - 광고 로더 (한 장의 NativeAd를 로드해 발행)

final class NativeAdLoader: NSObject, ObservableObject {
    @Published var nativeAd: NativeAd?

    private var adLoader: AdLoader?
    private var requested = false   // 스크롤로 셀이 재등장해도 중복 요청 방지

    func loadIfNeeded() {
        guard !requested else { return }
        requested = true

        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        let loader = AdLoader(adUnitID: AdConfig.nativeUnitID,
                              rootViewController: root,
                              adTypes: [.native],
                              options: nil)
        loader.delegate = self
        loader.load(AdConfig.makeRequest())
        self.adLoader = loader   // 로드 완료 전 해제되지 않도록 강한 참조 유지
    }
}

extension NativeAdLoader: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        #if DEBUG
        print("네이티브 광고 로드 성공: \(nativeAd.headline ?? "-")")
        #endif
        self.nativeAd = nativeAd
    }
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        #if DEBUG
        print("네이티브 광고 로드 실패: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - SwiftUI 진입점 (List 행에 넣는다)

struct NativeAdCard: View {
    @StateObject private var loader = NativeAdLoader()

    var body: some View {
        Group {
            if let ad = loader.nativeAd {
                NativeAdRepresentable(nativeAd: ad)
                    .frame(height: 305)   // 헤더+미디어(120)+본문2줄+버튼이 넉넉히 들어가는 높이
            } else {
                // 로드 전에도 행이 "존재"해야 List가 행을 만들고 .onAppear가 불려 로드가 시작된다.
                // (높이 0이면 List가 행을 안 만들어 로드 방아쇠가 안 당겨짐)
                // 투명하게 최소 높이만 주어 보이지 않으면서 로드만 트리거한다.
                Color.clear.frame(height: 1)
            }
        }
        .onAppear { loader.loadIfNeeded() }
    }
}

// MARK: - UIKit NativeAdView 래핑

private struct NativeAdRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> DiaryNativeAdView {
        let view = DiaryNativeAdView()
        view.configure(with: nativeAd)
        return view
    }

    func updateUIView(_ uiView: DiaryNativeAdView, context: Context) {
        uiView.configure(with: nativeAd)
    }
}

// MARK: - 앱 디자인에 맞춰 직접 구성한 네이티브 광고 뷰

final class DiaryNativeAdView: NativeAdView {

    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let adBadge = UILabel()
    private let adMediaView = MediaView()
    private let bodyLabel = UILabel()
    private let ctaLabel = UILabel()   // 버튼처럼 보이지만 탭 처리는 SDK가 담당

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupLayout() {
        // 카드 배경 + 소프트 섀도우 (폴라로이드 셀과 통일)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 3)

        // 아이콘
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // 제목 / 광고주
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.textColor = UIColor(AppColor.textPrimary)
        headlineLabel.numberOfLines = 1
        advertiserLabel.font = .systemFont(ofSize: 12)
        advertiserLabel.textColor = UIColor(AppColor.textSecondary)
        advertiserLabel.numberOfLines = 1

        let titleStack = UIStackView(arrangedSubviews: [headlineLabel, advertiserLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 2

        // "광고" 배지 (정책상 필수 표기)
        adBadge.text = "광고"
        adBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        adBadge.textColor = UIColor(AppColor.textSecondary)
        adBadge.textAlignment = .center
        adBadge.backgroundColor = UIColor(AppColor.accentSoft)
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.setContentHuggingPriority(.required, for: .horizontal)
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        adBadge.widthAnchor.constraint(equalToConstant: 34).isActive = true
        adBadge.heightAnchor.constraint(equalToConstant: 18).isActive = true

        let headerStack = UIStackView(arrangedSubviews: [iconImageView, titleStack, adBadge])
        headerStack.axis = .horizontal
        headerStack.spacing = 10
        headerStack.alignment = .center

        // 미디어(광고 이미지/영상)
        adMediaView.translatesAutoresizingMaskIntoConstraints = false
        adMediaView.clipsToBounds = true
        adMediaView.layer.cornerRadius = 10
        adMediaView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        // 본문
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = UIColor(AppColor.textSecondary)
        bodyLabel.numberOfLines = 2

        // CTA (버튼 느낌). userInteractionEnabled=false → 탭은 NativeAdView가 처리
        ctaLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        ctaLabel.textColor = .white
        ctaLabel.textAlignment = .center
        ctaLabel.backgroundColor = UIColor(AppColor.accent)
        ctaLabel.layer.cornerRadius = 10
        ctaLabel.clipsToBounds = true
        ctaLabel.isUserInteractionEnabled = false
        ctaLabel.translatesAutoresizingMaskIntoConstraints = false
        ctaLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let mainStack = UIStackView(arrangedSubviews: [headerStack, adMediaView, bodyLabel, ctaLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            // bottom을 <= 로 두면 스택이 내용 높이만큼만 차지 → 미디어/버튼이 억지로 늘어나거나 눌리지 않음.
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),
        ])

        // NativeAdView 자산 아웃렛 연결 (이게 있어야 클릭/노출이 정상 집계된다)
        self.headlineView = headlineLabel
        self.advertiserView = advertiserLabel
        self.iconView = iconImageView
        self.mediaView = adMediaView
        self.bodyView = bodyLabel
        self.callToActionView = ctaLabel
    }

    /// 로드된 광고 데이터를 뷰에 바인딩.
    func configure(with ad: NativeAd) {
        headlineLabel.text = ad.headline
        advertiserLabel.text = ad.advertiser
        advertiserLabel.isHidden = (ad.advertiser?.isEmpty ?? true)
        bodyLabel.text = ad.body
        bodyLabel.isHidden = (ad.body?.isEmpty ?? true)

        iconImageView.image = ad.icon?.image
        iconImageView.isHidden = (ad.icon == nil)

        adMediaView.mediaContent = ad.mediaContent

        ctaLabel.text = ad.callToAction
        ctaLabel.isHidden = (ad.callToAction?.isEmpty ?? true)

        // 마지막에 nativeAd를 지정해야 SDK가 자산 뷰들을 실제 광고와 연결한다.
        self.nativeAd = ad
    }
}
