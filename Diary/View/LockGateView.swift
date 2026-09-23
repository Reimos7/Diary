//
//  LockGateView.swift
//  Diary
//
//  앱 전체를 감싸는 잠금 게이트. 잠금 화면과 앱 스위처 커버를 본문 위에 덮는다.
//
//  [반드시 최상위 한 곳에만 둔다]
//  게이트를 MainTabView 안쪽이나 특정 탭에 두면, 위젯 딥링크(diary://compose)처럼
//  탭바를 거치지 않는 진입 경로로 잠금이 새어나간다. 진입점이 하나여야 빠짐이 없다.
//
//  [가리기(cover)와 잠금(lock)은 다른 축이다]
//  · 잠금  : 인증을 통과해야 사라진다. 앱을 떠났다 돌아온 뒤에 필요.
//  · 가리기: 인증과 무관하게, 화면이 스냅샷으로 남을 수 있는 순간에만 잠깐 덮는다.
//  앱 스위처에 일기 내용이 썸네일로 남는 것을 막는 게 가리기의 유일한 목적이다.
//

import SwiftUI

struct LockGateView<Content: View>: View {
    @EnvironmentObject private var lockManager: AppLockManager

    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            content()
                // 눈에만 안 보이게 하는 것으로는 부족하다.
                // 덮어둔 본문은 여전히 접근성 트리에 남아 있어 VoiceOver로 읽히고,
                // 그러면 잠금 화면 뒤의 일기 내용이 그대로 새어나간다.
                // 가려지는 동안에는 접근성과 터치 모두에서 본문을 제외한다.
                .accessibilityHidden(isObscured)
                .allowsHitTesting(!isObscured)

            // 잠금 화면. 인증을 통과할 때까지 본문을 완전히 덮는다.
            if lockManager.state != .unlocked {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else if lockManager.isCovered {
                // 해제된 상태에서 앱 스위처로 갈 때. 잠금 화면이 떠 있으면 이미 가려져 있으므로 불필요.
                PrivacyCoverView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lockManager.state)
        .animation(.easeInOut(duration: 0.15), value: lockManager.isCovered)
    }

    /// 잠금 화면이든 커버든, 본문 위에 무언가 덮여 있는 상태.
    private var isObscured: Bool {
        lockManager.state != .unlocked || lockManager.isCovered
    }
}

// MARK: - 잠금 화면

private struct LockScreenView: View {
    @EnvironmentObject private var lockManager: AppLockManager

    var body: some View {
        PinVerifyView(title: "PIN을 입력해 주세요") {
            lockManager.unlock()
        }
        .paperBackground()
        // 잠금이 꺼졌는데도 잠긴 채로 남아 앱이 열리지 않는 상황을 막는 안전장치.
        // (콜드런치 때 Keychain을 읽지 못해 보수적으로 잠근 경우가 여기서 회복된다)
        .onAppear { lockManager.revalidate() }
    }
}

// MARK: - 앱 스위처 커버

/// 스냅샷에 일기가 남지 않도록 덮는 화면.
/// 잠금 화면과 달리 아무 입력도 받지 않으며, 앱이 다시 활성화되면 즉시 사라진다.
///
/// 런치 스크린을 그대로 재사용한다.
/// - 콜드런치 / 앱 스위처 썸네일 / 커버가 모두 같은 얼굴이라 브랜드 인상이 일관된다.
/// - 로고가 커서 여러 앱이 늘어선 스위처에서 굿디를 찾기 쉽다.
/// - LaunchScreenView는 onAppear도 타이머도 환경 의존성도 없는 순수 뷰라
///   화면이 가려질 때마다 반복해서 그려도 부수효과가 없다.
private struct PrivacyCoverView: View {
    var body: some View {
        LaunchScreenView()
    }
}

#Preview {
    LockGateView {
        Color.white
    }
    .environmentObject(AppLockManager())
    .environmentObject(FontManager())
}
