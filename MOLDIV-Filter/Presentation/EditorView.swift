//
//  EditorView.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//
import SwiftUI

struct EditorView: View {
    @StateObject var viewModel: EditorViewModel

    var body: some View {
        VStack {
            Spacer()

            Group {
                if let image = viewModel.filteredImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("이미지를 불러오는 중...")
                        .foregroundColor(.gray)
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
                                .overlay(Text(filter.name.prefix(1)).font(.title)) // 임시 썸네일 대체

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
    }
}
