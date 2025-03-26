//
//  FullScreenImageView.swift
//  Diary
//
//  Created by Reimos on 3/3/25.
//

import SwiftUI

//  Identifiable을 따르는 구조체
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct FullscreenImageView: View {
    var image: UIImage
    @Environment(\.dismiss) var dismiss
    
    @State private var scale: CGFloat = 1.0  // 이미지의 현재 크기 (처음에는 원본 크기)
    @State private var lastScale: CGFloat = 1.0  // 마지막으로 저장된 스케일 값 (줌 후 스케일 추적)
    @State private var offset: CGSize = .zero  // 이미지의 현재 위치 (이동 값)
    @State private var lastOffset: CGSize = .zero  // 마지막으로 저장된 위치 (이동 후 위치 추적)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                // 이미지 표시
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(width: geometry.size.width, height: geometry.size.height)  // 화면 크기 맞추기
                    .scaleEffect(scale)  // 이미지 크기 조정 (스케일 값에 따라 확대/축소)
                    .offset(offset)  // 이미지 이동 (offset에 따라 이동)
                    .gesture(  // 제스처를 처리하는 부분
                        SimultaneousGesture(  // 동시에 여러 제스처를 사용할 수 있도록 설정
                            // 드래그 제스처 (이미지를 이동하는 제스처)
                            DragGesture()
                                .onChanged { value in  // 드래그가 변화할 때마다 호출
                                    if scale > 1.0 {  // 이미지가 확대된 상태에서만 이동 가능
                                        offset = CGSize(
                                            width: value.translation.width + lastOffset.width,  // 이전 오프셋에 드래그 이동량 추가
                                            height: value.translation.height + lastOffset.height
                                        )
                                    }
                                }
                                .onEnded { _ in  // 드래그가 끝났을 때 호출
                                    lastOffset = offset  // 마지막 오프셋을 저장
                                    limitOffset(geometry: geometry)  // 오프셋 제한
                                },
                            
                            // 확대/축소 제스처 (줌인/줌아웃)
                            MagnificationGesture()
                                .onChanged { value in  // 확대/축소 제스처가 변화할 때 호출
                                    let delta = value / lastScale  // 현재 스케일과 마지막 스케일의 차이를 계산
                                    lastScale = value  // 마지막 스케일을 업데이트
                                    let newScale = scale * delta  // 새로운 스케일 계산
                                    scale = max(1.0, min(newScale, 3.0))  // 최대 3배까지 확대, 최소 1배로 제한
                                }
                                .onEnded { _ in  // 제스처가 끝났을 때 호출
                                    lastScale = 1.0  // 마지막 스케일을 초기화
                                    limitOffset(geometry: geometry)  // 오프셋 제한
                                }
                                           )
                    )
                    .onTapGesture(count: 2) {  // 더블탭 제스처로 줌 동작
                        withAnimation(.spring()) {  // 스프링 애니메이션을 사용하여 부드럽게 동작
                            if scale > 1.0 {  // 이미지를 확대한 상태에서 더블탭하면 원본 크기로 복원
                                scale = 1.0  // 원본 크기로 되돌림
                                offset = .zero  // 이동된 위치 초기화
                                lastOffset = .zero  // 마지막 위치 초기화
                            } else {
                                scale = min(2.0, 4.0)  // 축소된 이미지에 대해 최대 4배 확대
                                limitOffset(geometry: geometry)  // 확대 후 위치 제한
                            }
                        }
                    }
                
                // 닫기버튼 x버튼 좌측으로
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.primary)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    Spacer()
                }
                
                
            }
        }
    }
    
    // 이미지 이동 범위 제한 (줌이 커지면 이미지를 너무 멀리 이동하지 않도록)
    private func limitOffset(geometry: GeometryProxy) {
        // 이미지가 확대되면 이동할 수 있는 최대 범위를 계산
        let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
        let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
        
        // 오프셋 값을 제한 (너무 멀리 이동하지 않도록)
        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
        lastOffset = offset  // 마지막 오프셋 업데이트
    }
}
