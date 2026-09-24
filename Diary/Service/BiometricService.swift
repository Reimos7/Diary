//
//  BiometricService.swift
//  Diary
//
//  Face ID / Touch ID 평가를 담당한다. 정책이나 화면은 모르고, "인증을 시도하고 결과를 알려주는" 일만 한다.
//
//  [정책은 .deviceOwnerAuthenticationWithBiometrics 로 고정한다]
//  비슷한 이름의 .deviceOwnerAuthentication 은 생체 실패 시 '기기 암호'를 받아준다.
//  그걸 쓰면 기기 암호를 아는 사람이 곧바로 일기를 열 수 있어서,
//  기기 암호와 별도로 일기 PIN을 두는 이 기능의 목적 자체가 사라진다.
//  굿디는 생체가 실패하면 반드시 '굿디 PIN'으로만 떨어져야 한다.
//
//  [LAContext는 매번 새로 만든다]
//  LAContext는 한 번 성공하면 그 결과를 일정 시간 캐시한다.
//  인스턴스를 재사용하면 두 번째 호출에서 얼굴을 대지 않았는데도 성공이 떨어질 수 있다.
//

import Foundation
import LocalAuthentication

enum BiometricKind {
    case none
    case touchID
    case faceID
    case opticID

    /// 사용자에게 보여줄 이름.
    ///
    /// Face ID / Touch ID는 애플이 정한 고유명사라 번역하지 않는다.
    /// 아이폰 SE·듀오와 Touch ID 아이패드에서는 "Touch ID"로 그대로 표시된다.
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return String(localized: "생체 인증")
        }
    }

    /// 목적격 조사까지 붙인 이름. ("Face ID를", "생체 인증을")
    ///
    /// 한국어 조사는 앞 글자의 받침에 따라 달라지는데, 이름이 기기마다 바뀌므로
    /// 문장 템플릿 하나로는 해결되지 않는다. 케이스별로 조사를 고정해 둔다.
    /// (영어·일본어 번역에서는 이 값이 통째로 이름으로만 쓰이면 된다)
    var displayNameWithObjectParticle: String {
        switch self {
        case .faceID, .touchID, .opticID: return "\(displayName)를"
        case .none: return String(localized: "생체 인증을")
        }
    }
}

enum BiometricError: Error {
    /// 하드웨어가 없거나 사용할 수 없음.
    case unavailable
    /// 기기에 등록된 생체 정보가 없음. (설정에서 등록 필요)
    case notEnrolled
    /// 연속 실패로 생체가 잠김. 기기를 암호로 한 번 풀어야 다시 쓸 수 있다.
    case lockout
    /// 사용자가 취소함. (프롬프트를 닫음)
    case userCancel
    /// 그 외 인식 실패.
    case failed
}

enum BiometricService {

    /// 이 기기에서 사용할 수 있는 생체 인증 종류.
    /// 하드웨어가 있어도 등록되어 있지 않으면 .none 이 아니라 종류가 그대로 나오므로,
    /// "쓸 수 있는가"는 canUse 로 따로 확인해야 한다.
    static var kind: BiometricKind {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }

    /// 지금 바로 생체 인증을 시도할 수 있는 상태인지.
    static var canUse: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// 등록된 생체 정보의 지문(identity).
    ///
    /// 기기에 얼굴/지문이 추가·삭제되면 이 값이 바뀐다.
    /// 저장해 둔 값과 비교하면 "내가 생체 잠금을 켠 이후에 누군가 자기 얼굴을 등록했는지"를 알 수 있다.
    /// 그런 경우 생체를 신뢰하지 않고 PIN을 요구해야 한다.
    /// (iOS 18부터 evaluatedPolicyDomainState가 domainState.biometry.stateHash로 대체됐다)
    static var domainState: Data? {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return nil
        }
        return context.domainState.biometry.stateHash
    }

    /// 생체 인증을 요청한다. 성공하면 그냥 반환하고, 실패하면 BiometricError를 던진다.
    static func authenticate(reason: String) async throws {
        let context = LAContext()

        // 시스템 폴백 버튼("암호 입력")을 숨긴다.
        // 이 버튼은 '기기 암호'를 받으려 하는데, 우리가 원하는 폴백은 굿디 PIN이다.
        // 버튼을 없애면 사용자는 프롬프트를 닫고 아래 키패드로 자연스럽게 내려온다.
        context.localizedFallbackTitle = ""

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw mapError(error)
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                             localizedReason: reason)
        } catch {
            throw mapError(error as NSError)
        }
    }

    // MARK: - 오류 매핑

    /// LAError를 앱이 다룰 수 있는 형태로 바꾼다.
    ///
    /// 여기서 빠뜨리는 케이스가 생기면 "생체도 안 되고 PIN 화면도 안 뜨는" 상태가 만들어진다.
    /// 그래서 알 수 없는 오류는 전부 .failed 로 모아, 최소한 PIN 입력은 항상 살아 있게 한다.
    private static func mapError(_ error: NSError?) -> BiometricError {
        guard let error else { return .failed }

        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable:
            return .unavailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel, .appCancel, .systemCancel:
            return .userCancel
        case .userFallback:
            // 폴백 버튼은 숨겨 두었지만, 방어적으로 취소와 동일하게 처리한다.
            return .userCancel
        default:
            return .failed
        }
    }
}
