//
//  View+Function.swift
//  Diary
//
//  Created by Reimos on 3/20/25.
//

import SwiftUI
// 키보드 내리기

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



