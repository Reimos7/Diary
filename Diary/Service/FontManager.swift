//
//  FontManager.swift
//  Diary
//
//  Created by Reimos on 4/15/25.
//

import SwiftUI

class FontManager: ObservableObject {
    // @AppStorage로 UserDefaults와 연동되어 선택된 폰트를 저장
    // 폰트 설정이 변경되면 UserDefaults에 저장되고, 앱 재실행 후에도 유지
    @AppStorage("selectedFont") var currentFont: String = "Cafe24DongdongOTF"
    
    static let fontList: [String] = ["dovemayo", "NanumPen", "Cafe24DongdongOTF", "Cafe24SyongsyongOTF"]
    
    init() {
        if let savedFont = UserDefaults.standard.string(forKey: "selectedFont") {
            self.currentFont = savedFont
        } else {
            self.currentFont = "Cafe24DongdongOTF"
        }
    }
    
    func changeFont(to fontName: String) {
        currentFont = fontName
    }
    
    static func displayName(for font: String) -> String {
        switch font {
        case "dovemayo":
            return "Dovemayo"
        case "NanumPen":
            return "Nanum Pen"
        case "Cafe24DongdongOTF":
            return "Cafe24 Dongdong"
        case "Cafe24SyongsyongOTF":
            return "Cafe24 Syongsyong"
        default:
            return font
        }
    }
}

// CustomFontModifier: ViewModifier로, 텍스트에 폰트를 적용하는 역할
struct CustomFontModifier: ViewModifier {
    @EnvironmentObject var fontManager: FontManager
    var size: CGFloat
    
    // ViewModifier의 필수 메서드 구현
    func body(content: Content) -> some View {
        content
            .font(.custom(fontManager.currentFont, size: size))
    }
}

// View에 customFont라는 메서드를 확장하여 폰트 수정 기능을 쉽게 적용
extension View {
    func customFont(size: CGFloat) -> some View {
        self.modifier(CustomFontModifier(size: size))
    }
}

// GlobalFontView: 전체 뷰에 전역 폰트를 적용하는 뷰
struct GlobalFontView<Content: View>: View {
    @EnvironmentObject var fontManager: FontManager
    var size: CGFloat
    let content: () -> Content
    
    // GlobalFontView는 content()에서 전달받은 뷰에 전역 폰트를 적용
    var body: some View {
        content()
            .modifier(CustomFontModifier(size: size))
    }
}
