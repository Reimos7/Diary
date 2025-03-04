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
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    @State private var imageUrl: [URL] = []
    // FocusState 이용하여 자동으로 키보드 보여주기
    @FocusState var focused: Bool
    
    let data: Diary?
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    //HStack {
                    // 저장된 이미지가 있으면 보여주고 없으면 ProgressView
                    if let paths = data?.imagePath, !paths.isEmpty {
                        ForEach(paths, id: \.self) { path in
                            if let url = URL(string: path) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                    
                                } placeholder: {
                                    ProgressView()
                                }
                                
                            } else {
                                Text("이미지 불러오기 실패")
                            }
                            
                        }
                        
                    }
                    //                        TextEditor(text: $content)
                    //                            .padding()
                    ResizableTextView(text: $content, placeholder: "일기를 입력해주세요!", maxTextWidth: UIScreen.main.bounds.width - 32)
                        .padding(.horizontal)
                        .focused($focused)
                    
                    
                    Spacer()
                    
                    
                    // 화면이 표시되는 시점에 초기화 코드 구현, 메모가 전달 되었으면 편집할 내용 표시
                    // 키보드 올리기 
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.focused = true
                            }
                            
                            if let data = data?.content {
                                content = data
                            }
                        }
                    //}
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
                        // 수정 버튼 누르면 키보드 내려서 showToast 사용자에게 보여주기
                        self.focused = false
                        
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

