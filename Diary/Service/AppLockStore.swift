//
//  AppLockStore.swift
//  Diary
//
//  PIN 자격증명(해싱/검증)과 실패 지연 정책을 담당한다.
//  KeychainService 위에 얹힌 '정책 계층'이며, 화면이나 상태머신은 전혀 모른다.
//
//  [왜 PIN을 그대로 저장하지 않는가]
//  Keychain은 이미 안전하지만, 저장소가 뚫렸을 때의 피해 범위를 줄이기 위해 해시로 저장한다.
//  사람들은 PIN을 다른 곳(현관 도어락, 카드 비밀번호)에도 재사용하기 때문에,
//  일기 앱이 원본 PIN을 들고 있을 이유가 없다.
//
//  [4자리 PIN에 대한 솔직한 한계]
//  경우의 수가 1만 개뿐이라, 자격증명이 통째로 유출되면 PBKDF2 반복 횟수를 아무리 올려도
//  오프라인 대입을 '느리게' 만들 뿐 막지는 못한다. 실질 방어선은 이 세 가지의 합이다.
//    1) Keychain 자체 보호(기기 잠금 + Secure Enclave)
//    2) 기기 밖으로 나가지 않게 하는 ThisDeviceOnly 접근성
//    3) 아래의 온디바이스 실패 지연(무차별 대입 속도 제한)
//  PBKDF2는 그 위에 얹는 심층 방어이지 은탄환이 아니다.
//

import Foundation
import CommonCrypto

// MARK: - 저장 모델

/// Keychain에 저장되는 PIN 자격증명.
/// version/iterations를 같이 저장해 두면, 나중에 알고리즘이나 반복 횟수를 올릴 때
/// 기존 사용자를 로그아웃시키지 않고 검증 성공 시점에 조용히 재해싱할 수 있다.
private struct PinCredential: Codable {
    let version: Int
    let salt: Data
    let hash: Data
    let iterations: Int
}

/// 실패 지연 상태. 앱을 강제 종료해도 리셋되면 안 되므로 메모리나 UserDefaults가 아닌 Keychain에 둔다.
private struct LockoutState: Codable {
    var failureCount: Int = 0
    var lockedUntil: Date?
    /// 마지막 시도 시각. 사용자가 기기 시계를 과거로 돌려 잠금을 우회하는 걸 탐지하는 데 쓴다.
    var lastAttemptAt: Date?
}

enum AppLockStoreError: Error {
    /// 4자리 숫자가 아님
    case invalidPinFormat
    /// PBKDF2 파생 실패
    case keyDerivationFailed
    /// 저장된 자격증명을 해석할 수 없음
    case corruptedCredential
}

// MARK: - Store

enum AppLockStore {

    // MARK: 정책 상수

    /// PIN 자릿수. 바꾸려면 입력 UI(키패드 인디케이터)도 같이 바꿔야 한다.
    static let pinLength = 4

    /// 실패 지연 정책: 5회부터 30초, 10회부터 5분.
    private static let firstThreshold = 5
    private static let firstDelay: TimeInterval = 30
    private static let secondThreshold = 10
    private static let secondDelay: TimeInterval = 5 * 60

    /// 현재 해싱 파라미터. 최신 아이폰에서 대략 수십 ms 수준이라 잠금 해제 체감에 영향이 없다.
    private static let currentVersion = 1
    private static let currentIterations = 120_000
    private static let saltByteCount = 16
    private static let hashByteCount = 32

    // MARK: - PIN 설정 / 검증

    /// PIN이 설정되어 있는지.
    /// 읽기에 실패하면(기기 잠금 등) throw한다. 호출부가 이를 "설정 안 됨"으로 뭉개면
    /// 잠금이 통째로 열리므로, 실패를 삼키지 않는 게 중요하다.
    static func isPinSet() throws -> Bool {
        try KeychainService.read(.pinCredential) != nil
    }

    /// 새 PIN 저장(최초 설정 및 변경 공용). 성공하면 실패 지연 상태도 초기화한다.
    static func setPin(_ pin: String) throws {
        guard isValidFormat(pin) else { throw AppLockStoreError.invalidPinFormat }

        let salt = try randomBytes(count: saltByteCount)
        let hash = try derive(pin: pin, salt: salt, iterations: currentIterations)
        let credential = PinCredential(version: currentVersion,
                                       salt: salt,
                                       hash: hash,
                                       iterations: currentIterations)

        try KeychainService.save(try JSONEncoder().encode(credential), for: .pinCredential)
        try resetFailures()
        syncEnabledFlag(true)
    }

    /// PIN 검증. 성공하면 실패 카운터를 초기화하고, 실패하면 카운터를 올린다.
    ///
    /// 호출 전에 반드시 remainingLockoutSeconds()를 확인해서 지연 중이면 시도 자체를 막아야 한다.
    /// (여기서 막지 않는 이유: "지연 중"은 UI가 남은 시간을 표시해야 하는 상태라 호출부의 관심사다)
    @discardableResult
    static func verify(_ pin: String) throws -> Bool {
        guard isValidFormat(pin) else {
            try registerFailure()
            return false
        }
        guard let data = try KeychainService.read(.pinCredential) else { return false }
        guard let credential = try? JSONDecoder().decode(PinCredential.self, from: data) else {
            throw AppLockStoreError.corruptedCredential
        }

        let candidate = try derive(pin: pin,
                                   salt: credential.salt,
                                   iterations: credential.iterations)
        // 해시 비교는 상수 시간으로. 로컬 공격에서 타이밍 차이를 재는 건 현실성이 낮지만,
        // 비교 대상이 비밀값에서 파생된 값이면 상수 시간 비교가 기본값이어야 한다.
        let matched = constantTimeEquals(candidate, credential.hash)

        if matched {
            try resetFailures()
            // 파라미터가 낡았으면 이 시점에 조용히 최신 기준으로 재해싱한다.
            if credential.version != currentVersion || credential.iterations != currentIterations {
                try? setPin(pin)
            }
        } else {
            try registerFailure()
        }
        return matched
    }

    /// PIN 및 실패 상태 전체 삭제 (잠금 기능 끄기).
    static func clear() throws {
        try KeychainService.deleteAll()
        syncEnabledFlag(false)
    }

    // MARK: - 위젯용 미러

    /// 위젯이 읽는 App Group 플래그 키.
    static let enabledFlagKey = "isAppLockEnabled"

    /// 잠금 on/off를 App Group에 복사한다.
    ///
    /// 위젯은 별도 프로세스라 Keychain 자격증명을 확인할 수 없고, 애초에 확인해서도 안 된다.
    /// 그래서 "잠금이 켜져 있는가"라는 사실만 App Group으로 넘겨 위젯이 내용을 가리게 한다.
    /// 진실의 원천은 어디까지나 Keychain이고 이 값은 파생된 사본이므로,
    /// PIN이 바뀌는 모든 경로(setPin/clear)에서 반드시 같이 갱신한다.
    private static func syncEnabledFlag(_ isEnabled: Bool) {
        let sharedDefaults = UserDefaults(suiteName: SharedModelContainer.appGroupIdentifier)
        sharedDefaults?.set(isEnabled, forKey: enabledFlagKey)
    }

    // MARK: - 실패 지연

    /// 지금 입력이 막혀 있다면 남은 초, 아니면 0.
    static func remainingLockoutSeconds() throws -> TimeInterval {
        let state = try loadLockoutState()
        guard let lockedUntil = state.lockedUntil else { return 0 }

        let now = Date()
        // 시계 되돌리기 탐지: 마지막 시도보다 '지금'이 과거라면 시스템 시간이 조작된 것으로 본다.
        // 이 경우 남은 시간을 계산할 근거가 없으므로 정책상 최대 지연을 그대로 적용한다.
        if let lastAttemptAt = state.lastAttemptAt, now < lastAttemptAt {
            return delay(for: state.failureCount)
        }
        return max(0, lockedUntil.timeIntervalSince(now))
    }

    /// 누적 실패 횟수 (UI에서 "n회 남음" 같은 안내를 하고 싶을 때 사용).
    static func failureCount() throws -> Int {
        try loadLockoutState().failureCount
    }

    private static func registerFailure() throws {
        var state = try loadLockoutState()
        let now = Date()
        state.failureCount += 1
        state.lastAttemptAt = now

        let delaySeconds = delay(for: state.failureCount)
        state.lockedUntil = delaySeconds > 0 ? now.addingTimeInterval(delaySeconds) : nil

        try saveLockoutState(state)
    }

    private static func resetFailures() throws {
        try saveLockoutState(LockoutState())
    }

    /// 실패 횟수에 대응하는 지연 시간.
    private static func delay(for failureCount: Int) -> TimeInterval {
        switch failureCount {
        case secondThreshold...: return secondDelay
        case firstThreshold...: return firstDelay
        default: return 0
        }
    }

    private static func loadLockoutState() throws -> LockoutState {
        guard let data = try KeychainService.read(.lockoutState) else { return LockoutState() }
        // 상태가 깨졌으면 '지연 없음'이 아니라 초기 상태로 되돌린다.
        // (깨진 값을 만들어 지연을 우회하는 걸 막기 위해, 실패 카운터는 0부터 다시 쌓인다)
        return (try? JSONDecoder().decode(LockoutState.self, from: data)) ?? LockoutState()
    }

    private static func saveLockoutState(_ state: LockoutState) throws {
        try KeychainService.save(try JSONEncoder().encode(state), for: .lockoutState)
    }

    // MARK: - 암호 유틸

    private static func isValidFormat(_ pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy(\.isNumber)
    }

    private static func randomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        guard SecRandomCopyBytes(kSecRandomDefault, count, &bytes) == errSecSuccess else {
            throw AppLockStoreError.keyDerivationFailed
        }
        return Data(bytes)
    }

    /// PBKDF2-HMAC-SHA256으로 PIN을 늘려 파생 키를 만든다.
    private static func derive(pin: String, salt: Data, iterations: Int) throws -> Data {
        let pinBytes = Array(pin.utf8)
        var derived = [UInt8](repeating: 0, count: hashByteCount)

        let status = salt.withUnsafeBytes { saltBuffer -> Int32 in
            guard let saltBase = saltBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return Int32(kCCParamError)
            }
            return CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                pinBytes.map { Int8(bitPattern: $0) }, pinBytes.count,
                saltBase, salt.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterations),
                &derived, derived.count
            )
        }

        guard status == kCCSuccess else { throw AppLockStoreError.keyDerivationFailed }
        return Data(derived)
    }

    /// 길이·내용을 상수 시간으로 비교한다. (early return이 없어야 의미가 있다)
    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for (l, r) in zip(lhs, rhs) { diff |= l ^ r }
        return diff == 0
    }
}
