//
//  EmailManager.swift
//  Diary
//
//  Created by Reimos on 4/16/25.
//

import SwiftUI

struct EmailManager {
    // 개발자 이메일
    let toAddress: String
    // 제목
    let subject: String
    // 메일 내용 (다국어 지원)
    var body: String {
        String(localized: "문의해 주셔서 감사합니다.\n더 좋은 서비스를 위해 항상 노력하겠습니다.\n\n문의하기:")
    }
    
    // openURL
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("ERROR: 현재 기기는 이메일을 지원하지 않습니다.")
            }
        }
    }
}
