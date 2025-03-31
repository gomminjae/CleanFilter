//
//  EditorView.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//

import SwiftUI
import PhotosUI

struct EditorView: View {
    @StateObject var viewModel: EditorViewModel
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            // 이미지 뷰
            Group {
                if let image = viewModel.filteredImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipped() // ← 중요: 잘린 부분 자르기
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("이미지 추가")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .frame(maxHeight: 400)
            .background(Color.black)
            .padding()

            // 필터 썸네일 바
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.filterList, id: \.id) { filter in
                        VStack {
                            if let preview = viewModel.filterThumbnails[filter.id] {
                                Image(uiImage: preview)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    .overlay(Text(filter.name.prefix(1)))
                            }

                            Text(filter.name)
                                .font(.caption2)
                                .foregroundColor(viewModel.selectedFilter?.id == filter.id ? .blue : .primary)
                        }
                        .padding(4)
                        .background(viewModel.selectedFilter?.id == filter.id ? Color.blue.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            viewModel.selectFilter(filter)
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .onAppear {
            viewModel.loadFilters()
        }
        .onChange(of: selectedItem) {
            guard let item = selectedItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.setOriginalImage(image)
                }
            }
        }
    }
}
