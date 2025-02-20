//
//  Item.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import Foundation
import SwiftData
// 일기 내용, 날짜
@Model
class Diary {
    var content: String
    var date: Date
    
    init(content: String, date: Date) {
        self.content = content
        self.date = date
    }
}
