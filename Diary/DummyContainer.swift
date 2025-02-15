//
//  DummyContainer.swift
//  Diary
//
//  Created by Reimos on 2/16/25.
//

import Foundation
struct DummyContainer {
    let weatherIcon: String
    let date: String
    let week: String
}

extension DummyContainer {
    static var preview: DummyContainer {
        return DummyContainer(weatherIcon: "sun.max.fill", date: "2025년3월9일", week: "화요일")
    }
}
