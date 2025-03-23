//
//  Item.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import Foundation
import SwiftData
// 일기 내용, 날짜, 이미지 경로 저장
@Model
class Diary {
    var content: String
    var date: Date
    // 직접 이미지를 데이터로 저장하는 것이 아니라, 파일 시스템에 저장된 이미지의 경로를 저장하여 관리
    var imagePath: [String]? // 이미지 경로만 저장
    var currentWearherImage: String? // 현재 날씨 이미지가 있을 수 있고 없을 수 있음
    
    init(content: String, date: Date, imagePath: [String]? = nil, currentWeatherImage: String? = nil) {
        self.content = content
        self.date = date
        self.imagePath = imagePath
        self.currentWearherImage = currentWeatherImage
    }
}
