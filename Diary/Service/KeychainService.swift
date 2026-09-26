//
//  KeychainService.swift
//  Diary
//
//  앱 잠금(PIN)에 필요한 값을 Keychain에 안전하게 넣고 빼는 저수준 계층.
//
//  [설계 원칙]
//  - 이 파일은 "바이트 저장소"일 뿐, PIN을 어떻게 해싱하는지/몇 번 틀리면 잠그는지 같은
//    '정책'은 전혀 모른다. 정책은 AppLockStore가 담당한다.
//  - 접근성은 kSecAttrAccessibleWhenUnlockedThisDeviceOnly 로 고정한다.
//    · WhenUnlocked      → 기기가 잠겨 있는 동안에는 읽을 수 없다 (백그라운드 접근 차단)
//    · ThisDeviceOnly    → iCloud 키체인 동기화 / 백업 복원으로 다른 기기에 넘어가지 않는다
//    후속 '백업 기능' 브랜치에서 일기는 백업되더라도 PIN은 절대 따라가면 안 되므로 중요하다.
//  - "값이 없다"와 "읽기에 실패했다"를 반드시 구분한다. (아래 read 주석 참고)
//

import Foundation
import Security

enum KeychainError: Error, Equatable {
    /// 기기가 잠겨 있어 접근이 거부됨. "값이 없음"과 절대 같게 취급하면 안 된다.
    case interactionNotAllowed
    /// 저장된 값이 Data가 아니거나 손상됨
    case invalidData
    /// 그 외 OSStatus
    case unexpected(OSStatus)
}

enum KeychainService {

    /// 이 앱의 잠금 관련 항목을 묶는 네임스페이스. 다른 기능이 생겨도 서로 안 섞이게 한다.
    private static let service = "com.reimos7.goodd.applock"

    /// Keychain에 저장하는 항목들. 새 항목이 생기면 여기에만 추가하면 deleteAll도 자동 대응된다.
    enum Account: String, CaseIterable {
        /// PIN의 salt + 해시 + 파라미터를 묶은 자격증명 (PinCredential을 JSON 인코딩)
        case pinCredential = "applock.pin.credential"
        /// 실패 횟수 / 잠금 해제 시각 (LockoutState를 JSON 인코딩)
        case lockoutState = "applock.lockout.state"
        /// 생체 인증 사용 여부 + 등록 상태 지문 (BiometricSetting을 JSON 인코딩)
        case biometricSetting = "applock.biometric.setting"
    }

    // MARK: - CRUD

    /// 저장(없으면 추가, 있으면 갱신).
    ///
    /// SecItemAdd는 같은 키가 이미 있으면 errSecDuplicateItem으로 실패한다.
    /// 이걸 처리하지 않으면 "PIN 변경이 조용히 실패하고 예전 PIN이 그대로 남는" 버그가 난다.
    /// delete → add 순서로 짜는 방법도 있지만, delete 성공 후 add가 실패하면
    /// 값이 통째로 사라져 사용자가 앱에서 영영 못 나오게 된다. 그래서 add → update 폴백을 쓴다.
    static func save(_ data: Data, for account: Account) throws {
        var query = baseQuery(for: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let attributes = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(baseQuery(for: account) as CFDictionary,
                                             attributes as CFDictionary)
            guard updateStatus == errSecSuccess else { throw mapError(updateStatus) }
        default:
            throw mapError(status)
        }
    }

    /// 읽기. 값이 없으면 nil, 읽기 자체가 실패하면 throw.
    ///
    /// 여기서 errSecItemNotFound만 nil로 내리는 게 핵심이다.
    /// 만약 모든 실패를 nil로 뭉개면, 기기 잠금 등으로 읽기가 거부됐을 때
    /// 앱은 "PIN이 설정된 적 없다"고 판단해서 잠금을 통째로 열어버린다.
    static func read(_ account: Account) throws -> Data? {
        var query = baseQuery(for: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { throw KeychainError.invalidData }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw mapError(status)
        }
    }

    /// 삭제. 이미 없으면 성공으로 친다(멱등).
    static func delete(_ account: Account) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw mapError(status)
        }
    }

    /// 잠금 관련 항목 전체 삭제 (잠금 해제 시 사용).
    static func deleteAll() throws {
        for account in Account.allCases {
            try delete(account)
        }
    }

    // MARK: - Helpers

    private static func baseQuery(for account: Account) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            // 기본값도 false지만, iCloud 키체인으로 새어나가지 않도록 명시적으로 못 박는다.
            kSecAttrSynchronizable as String: false
        ]
    }

    private static func mapError(_ status: OSStatus) -> KeychainError {
        status == errSecInteractionNotAllowed ? .interactionNotAllowed : .unexpected(status)
    }
}
