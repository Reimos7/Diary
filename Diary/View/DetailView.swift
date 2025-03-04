import SwiftUI

// 일기 상세 화면
struct DetailView: View {
    
    @State private var showEditComposeView: Bool = false
    @State private var showDeleteAlert: Bool = false
    @EnvironmentObject var manager: SwiftDataManager
    @Environment(\.dismiss) var dismiss
    
    // 선택한 이미지를 파일로 저장한 후 해당 파일의 URL을 저장하는 배열
    @State private var imageUrl: [URL] = []
    
    let data: Diary
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    // HStack {
                    
                    // 저장된 이미지가 있으면 보여주고 없으면 ProgressView
                    if let paths = data.imagePath, !paths.isEmpty {
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
                    
                    Text(data.content)
                        .padding()
                    
                    Spacer(minLength: 0)
                    //}
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
