//
//  EditorView.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//
import SwiftUI
import PhotosUI

enum EditorMode {
    case viewOnly
    case editing
}

struct EditorView: View {
    @StateObject var viewModel: EditorViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var mode: EditorMode = .viewOnly
    
    
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    viewModel.saveToPhotoLibrary()
                }) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(10)
                }
            }
            Group {
                if let image = viewModel.filteredImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .clipped()
                        .padding()
                }
            }
            .frame(maxHeight: .infinity)
            .padding(.vertical, 20)

            Spacer()

            if mode == .editing {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 4) {
                        ForEach(viewModel.filterList, id: \.id) { filter in
                            VStack {
                                if let preview = viewModel.filterThumbnails[filter.id] {
                                    Image(uiImage: preview)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 70)
                                        .clipped()
                                        .cornerRadius(8)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 80)
                                        .cornerRadius(8)
                                }

                                Text(filter.name)
                                    .font(.caption2)
                                    .foregroundColor(viewModel.selectedFilter?.id == filter.id ? .blue : .primary)
                            }
                            .padding(4)
                            .background(viewModel.selectedFilter?.id == filter.id ? Color.blue.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                            .scaleEffect(viewModel.selectedFilter?.id == filter.id ? 1.15 : 1.0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    viewModel.selectFilter(filter)
                                }
                            }
                        }
                    }
                    .padding(.horizontal,25)
                    .padding(.vertical,30)
                }
                .background(Color.black.opacity(0.5))
                .frame(height: 100)
                
            }

            HStack {
                if mode == .editing {
                   
                    Button(action: {
                        mode = .viewOnly
                        viewModel.resetFilter()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }

                    Spacer()

                    Text("필터효과")
                        .foregroundColor(.white)
                        .font(.subheadline)

                    Spacer()

                    Button(action: {
                        mode = .viewOnly
                        viewModel.confirmFilter()
                    }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                } else {
                    HStack(spacing: 12) {
                        // 이미지 추가 버튼
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("이미지")
                            }
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        // 필터 버튼
                        Button(action: {
                            mode = .editing
                        }) {
                            HStack {
                                Image(systemName: "camera.filters")
                                Text("필터")
                            }
                            .font(.subheadline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(Color.black)
        }
        .background(Color.black.edgesIgnoringSafeArea(.bottom))
        .onReceive(viewModel.$saveSuccess) { success in
            if success { 
                showSaveSuccessAlert = true
            }
        }
        .onReceive(viewModel.$saveErrorMessage) { message in
            if message != nil {
                showSaveErrorAlert = true
            }
        }
        .alert("사진이 저장되었습니다.", isPresented: $showSaveSuccessAlert) {
            Button("확인", role: .cancel) {
                viewModel.saveSuccess = false
            }
        }
        .alert("저장 실패", isPresented: $showSaveErrorAlert) {
            Button("확인", role: .cancel) {
                viewModel.saveErrorMessage = nil
            }
        } message: {
            Text(viewModel.saveErrorMessage ?? "알 수 없는 오류")
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
