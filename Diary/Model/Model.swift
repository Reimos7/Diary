//
//  Item.swift
//  Diary
//
//  Created by Reimos on 2/15/25.
//

import Foundation
import SwiftData
// 일기 제목, 내용, 날짜 
@Model
final class Item {
    var title: String
    var content: String
    var date: Date
    
    init(title: String, content: String, date: Date = Date.now) {
        self.title = title
        self.content = content
        self.date = date
    }
    
}
