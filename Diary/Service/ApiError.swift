//
//  ApiError.swift
//  Diary
//
//  Created by Reimos on 2/18/25.
//

import Foundation
// 에러 처리

enum ApiError: Error {
    // 알 수 없는 에러
    case unknown
    // url이 잘못 되었을때
    case invalidUrl(String)
    // 응답이 잘못 되었을때
    case invalidResponse
    // 요청이 실패 했을때
    case failed(Int)
    // 데이터가 없을때
    case emptyData
}
