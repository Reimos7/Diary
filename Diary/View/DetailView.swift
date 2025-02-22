import SwiftUI

// 일기 상세 화면
struct DetailView: View {
    
    @State private var showEditComposeView = false
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss
    
    let data: Diary
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    HStack {
                        Text(data.content)
                            .padding()
                        Spacer(minLength: 0)
                    }
                    Text(dateFormatter.string(from: data.date))
                        .padding()
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            // MARK: - 편집,삭제 메뉴 버튼
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            manager.deleteDiaryData(entry: data)
                            dismiss()
                        } label: {
                            Text("삭제")
                        }
                        
                        Button {
                            showEditComposeView = true
                        } label: {
                            Text("편집")
                        }
                    } label: {
                        Image(systemName:  "ellipsis")
                    }
                }
            }
            
            .fullScreenCover(isPresented: $showEditComposeView) {
                EditComposeView(data: data)
            }
        }
        
    }
}
