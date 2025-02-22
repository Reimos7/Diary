//
//  EditComposeView.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import SwiftUI

struct EditComposeView: View {
    
    @State private var content: String = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var manager: SwiftDataManager
    
    let data: Diary?
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    HStack {
                        TextEditor(text: $content)
                            .padding()
                        // 화면이 표시되는 시점에 초기화 코드 구현, 메모가 전달 되었으면 편집할 내용 표시
                            .onAppear {
                                if let data = data?.content {
                                    content = data
                                }
                            }
                    }
                    Text(DateFormatter.dateFormatter.string(from: data?.date ?? Date.now))
                        .padding()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("닫기")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let data = data else { return }
                        manager.updateDiaryData(entry: data, newContent: content)
                        dismiss()
                    } label: {
                        Text("수정")
                    }

                }
                
            }
            
        }
        
    }
}

