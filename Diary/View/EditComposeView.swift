//
//  EditComposeView.swift
//  Diary
//
//  Created by Reimos on 2/22/25.
//

import SwiftUI

struct EditComposeView: View {
    
    @State private var content: String = ""
    @State private var showToast: Bool = false
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
                        showToast = true
                        // 저장하면 toast 메시지로 알려주고 1초 뒤에 dissmiss 실행
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showToast = false
                            dismiss()
                        }
                    } label: {
                        Text("수정")
                    }
                }
                
            }
            // 저장하면 toast 메시지로 알려줌
            if showToast {
                VStack {
                    Text("일기를 수정했어요!")
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showToast)
                .padding(.bottom, 50)
                
            }
        }
        
    }
}

