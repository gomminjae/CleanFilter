//
//  EditorView.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//
import SwiftUI

struct EditorView: View {
    @State private var selectedFilter: FilterType = .original

    var body: some View {
        VStack {
            Spacer()
            
            Image("sample") // Assets.xcassets에 등록된 예시 이미지
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 400)
                .background(Color.black)
                .padding()

            // 필터 선택 바 (수평 스크롤)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(FilterType.allCases, id: \.self) { filter in
                        VStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(Text(filter.emoji).font(.largeTitle)) // 임시 썸네일 대체

                            Text(filter.name)
                                .font(.caption)
                                .foregroundColor(filter == selectedFilter ? .blue : .primary)
                        }
                        .padding(8)
                        .background(filter == selectedFilter ? Color.blue.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }
}

#Preview {
    EditorView()
}


enum FilterType: CaseIterable {
    case original, warm, cool, pastel, noir

    var name: String {
        switch self {
        case .original: return "Original"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .pastel: return "Pastel"
        case .noir: return "Noir"
        }
    }

    var emoji: String {
        switch self {
        case .original: return "🖼️"
        case .warm: return "🔥"
        case .cool: return "❄️"
        case .pastel: return "🌸"
        case .noir: return "🌑"
        }
    }
}
