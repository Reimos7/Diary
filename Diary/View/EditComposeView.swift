//
//  EditComposeView.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import SwiftUI

struct EditComposeView: View {
    let data: Diary
    
    var body: some View {
        Text("\(data.content)")
        Text("\(data.date.formatted())")
    }
}

