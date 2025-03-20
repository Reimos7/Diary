//
//  DiaryCell.swift
//  Diary
//
//  Created by Reimos on 2/21/25.
//

import SwiftUI
// ListView에서 보여주는 Diary Cell
struct DiaryCell: View {
    let diaryCellData: Diary
    // 모든 기기에서 동일한 너비
    private let fixedWidth = UIScreen.main.bounds.width * 0.85
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            // 날짜 표시
            Text(DateFormatter.dateFormatter.string(from: diaryCellData.date))
                .padding()
                .font(.footnote)
                .foregroundStyle(.primary) // 다크 모드 대응
            
            // 이미지가 있을 경우 표시
            if let paths = diaryCellData.imagePath, !paths.isEmpty {
                ForEach(paths, id: \.self) { path in
                    if let url = URL(string: path) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } placeholder: {
                            ProgressView()
                        }
                        
                    }
                    
                }
            }
            // 내용
            Text(diaryCellData.content)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: fixedWidth - 20, alignment: .leading)
                .foregroundStyle(.primary) // 다크 모드 대응
                .padding(.bottom, 10)
        }
        .padding()
        // 가로 크기 고정
        .frame(width: fixedWidth)
        // 카드 형식의 UI
        //.background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color(uiColor: .lightGray) : Color.white))
        // 그림자 효과
        .shadow(radius: 2)
    }
}

#Preview {
    DiaryCell(diaryCellData: Diary(content: "test", date: Date.now))
}
