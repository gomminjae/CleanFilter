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
            Spacer()

            Group {
                if let image = viewModel.filteredImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("이미지 추가")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .background(Color.black)
            .padding()

            // 필터 선택 바
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.filterList, id: \.id) { filter in
                        VStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(Text(filter.name.prefix(1)).font(.title)) 

                            Text(filter.name)
                                .font(.caption)
                                .foregroundColor(viewModel.selectedFilter?.id == filter.id ? .blue : .primary)
                        }
                        .padding(8)
                        .background(viewModel.selectedFilter?.id == filter.id ? Color.blue.opacity(0.1) : Color.clear)
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
