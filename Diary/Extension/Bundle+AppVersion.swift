//
//  Bundle+AppVersion.swift
//  Diary
//
//  앱 버전 문자열을 Info.plist에서 읽어오는 헬퍼.
//  버전을 화면에 하드코딩하지 않고 실제 빌드 값을 그대로 표시하기 위함.
//

import Foundation

extension Bundle {
    /// Info.plist의 CFBundleShortVersionString(예: "1.3.0").
    /// 값이 없을 경우 빈 문자열을 반환한다.
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
