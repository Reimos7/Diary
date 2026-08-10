//
//  AppDelegate.swift
//  Diary
//
//  Firebase 통합 진입점.
//  SwiftUI(@main App)에는 앱 생명주기/원격 알림 콜백이 없으므로,
//  UIApplicationDelegateAdaptor로 UIKit AppDelegate를 연결하여
//  Firebase 초기화 · APNs 토큰 연동 · FCM 토큰 수신을 이 한 곳에서 관리
//
//  [역할 분리 — 중요]
//  - AppDelegate      : Firebase 초기화 + APNs↔FCM 토큰 "연동"만 담당
//  - NotificationManager : 알림의 "표시/탭 처리"(UNUserNotificationCenterDelegate) 담당
//  두 역할을 섞지 않는다
//  UNUserNotificationCenter의 delegate는 단 하나만 유효하므로,
//  기존 NotificationManager를 그대로 재사용하고 여기서 중복 지정하지 않는다.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {

    // 앱 실행 직후 최초 1회 호출되는 지점.
    // Firebase는 어떤 Firebase API보다 먼저 configure() 되어야 하므로 여기서 초기화한다.
    // 이 한 줄만으로 Analytics와 Crashlytics는 자동으로 동작을 시작한다.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1) Firebase 코어 초기화.
        //    GoogleService-Info.plist가 타겟에 없으면 여기서 크래시가 나므로 가장 먼저 의심할 지점.
        FirebaseApp.configure()

        // 2) FCM 토큰 갱신 콜백을 받기 위한 델리게이트 지정.
        Messaging.messaging().delegate = self

        // 3) APNs 원격 알림 등록.
        //    이 호출이 있어야 아래 didRegisterForRemoteNotifications 콜백으로 디바이스 토큰이 전달된다.
        //    (실제 알림 권한 요청/표시는 기존 NotificationManager가 담당하므로 여기서는 등록만 한다)
        application.registerForRemoteNotifications()

        // 4) Google Mobile Ads(AdMob) SDK 시작.
        //    한 번만 호출하면 되며, 이후 배너/전면 광고를 로드할 수 있다.
        //    완료 핸들러는 지금은 불필요하므로 nil. (첫 광고 로드 전에 반드시 start되어 있어야 함)
        MobileAds.shared.start(completionHandler: nil)

        // 5) 전면 광고 미리 로드. 저장 시점에 바로 띄울 수 있도록 준비만 해둔다.
        InterstitialAdManager.shared.preload()

        return true
    }

    // MARK: - APNs 토큰 연동
    // APNs 등록 성공 시 호출, 받은 디바이스 토큰을 Firebase에 넘겨야
    // FCM이 이 기기를 식별하고 실제 푸시를 전달할 수 있다 (이 연결이 빠지면 푸시가 도달하지 않음)
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // APNs 등록 실패 시 호출, 시뮬레이터/네트워크 문제 등에서 발생 가능
    // 로그만 남기고 앱은 정상 동작하도록 둔다(푸시만 비활성, 크래시 아님)
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("APNs 등록 실패: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate (FCM 토큰 수신)
extension AppDelegate: MessagingDelegate {

    // FCM 토큰이 발급/갱신될 때마다 호출
    // 서버가 있다면 이 토큰을 서버로 전송해 저장하지만
    // 이 프로젝트는 서버가 없으므로 콘솔 테스트 발송을 위해 로그로 출력
    // (Firebase 콘솔 > Messaging > "테스트 메시지 전송"에 이 토큰을 붙여 넣어 사용)
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM 등록 토큰: \(fcmToken ?? "nil")")
    }
}
