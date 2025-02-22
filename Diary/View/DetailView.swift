import SwiftUI

// 일기 상세 화면
struct DetailView: View {
    
    @State private var showEditComposeView: Bool = false
    @State private var showDeleteAlert: Bool = false
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss
    
    let data: Diary
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    HStack {
                        Text(data.content)
                            .padding()
                        Spacer(minLength: 0)
                    }
                    Text(DateFormatter.dateFormatter.string(from: data.date))
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
                            showDeleteAlert = true
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
            } // alert로 삭제
            .alert("삭제", isPresented: $showDeleteAlert) {
                Button(role: .destructive) {
                    manager.deleteDiaryData(entry: data)
                    dismiss()
                } label: {
                    Text("삭제")
                }
            } message: {
                Text("일기를 삭제할까요?")
            }
            
            .fullScreenCover(isPresented: $showEditComposeView) {
                EditComposeView(data: data)
            }
        }
        
    }
}
