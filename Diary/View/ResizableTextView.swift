//
//  ResizableTextView.swift
//  Diary
//
//  Created by Reimos on 3/4/25.
//

import SwiftUI
// placeholder 및 자동 줄 바꿈 구현 뷰
struct ResizableTextView: View {
    @Binding var text: String
    let placeholder: String
    let font: UIFont = UIFont.systemFont(ofSize: 14)
    // TextEditor 최대 너비
    var maxTextWidth: CGFloat
    // TextEditor 높이
    @State private var textHeight: CGFloat = 120
    
    
    var body: some View {
        TextEditor(text: $text)
            .frame(height: textHeight)
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .background(Color.clear)
            .border(Color.gray.opacity(0.2), width: 1)
            .overlay(
                // placeholder를 overlay로 배치하여 항상 최상위에 유지
                Group {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(Color.gray)
                            .padding(.horizontal, 12)
                            .padding(.top, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                },
                // placeholder를 textEditor의 왼쪽 상단에 정렬
                alignment: .topLeading
                
            )
            .onAppear { calculateHeight() }
            .onChange(of: text) { _ in calculateHeight() }
    }

    private func calculateHeight() {
        let lineCount = autoLineCount(text: text, font: font, maxTextWidth: maxTextWidth - 40)
        textHeight = max(120, lineCount * (font.lineHeight + 5))
    }

    private func autoLineCount(text: String, font: UIFont, maxTextWidth: CGFloat) -> CGFloat {
        var lineCount: CGFloat = 0
        text.components(separatedBy: "\n").forEach { line in
            let currentTextWidth = (line as NSString).size(withAttributes: [.font: font]).width
            lineCount += ceil(currentTextWidth / maxTextWidth)
        }
        return max(1, lineCount)
    }
}
