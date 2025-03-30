//
//  EditorViewModel.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import UIKit

@MainActor
protocol EditorViewBindable {
    var filterList: [FilterConfig] { get }
    var originalImage: UIImage? { get }
    var filteredImage: UIImage? { get }
    
    func loadFilters()
    func selectFilter(_ filter: FilterConfig)
    func setOriginalImage(_ image: UIImage)
    
    
}

@MainActor
class EditorViewModel: EditorViewBindable, ObservableObject {
    
    private let loadFilterUseCase: LoadFilterUseCase
    private let applyFilterUseCase: ApplyFilterUseCase
    
    
    @Published var filterList: [FilterConfig] = []
    @Published var originalImage: UIImage?
    @Published var filteredImage: UIImage?
    
    @Published var selectedFilter: FilterConfig?
    
    
    
    
    init(loadFilterUseCase: LoadFilterUseCase, applyFilterUseCase: ApplyFilterUseCase) {
        self.loadFilterUseCase = loadFilterUseCase
        self.applyFilterUseCase = applyFilterUseCase
    }
    
    func loadFilters() {
        Task {
            do {
                var filters = try await loadFilterUseCase.execute()
                let originalFilter = FilterConfig(id: "original", name: "원본", shader: "", thumbnail: "", parameters: [:])
                filters.insert(originalFilter, at: 0)
                self.filterList = filters

                // ✅ 이미지가 이미 선택된 상태라면 원본 필터 다시 적용
                if originalImage != nil {
                    selectFilter(originalFilter)
                }

            } catch {
                print("필터 로딩 실패: \(error)")
            }
        }
    }
    
    func selectFilter(_ filter: FilterConfig) {
        selectedFilter = filter
        applySelectedFilter()
        
    }
    
    func setOriginalImage(_ image: UIImage) {
        originalImage = image

        if let original = filterList.first(where: { $0.id == "original" }) {
            selectFilter(original)
        } else {
            // 필터 리스트가 아직 로드되지 않았을 때 대비
            filteredImage = image
        }
    }
    private func applySelectedFilter() {
        guard let filter = selectedFilter, let original = originalImage else { return }

        // 🔥 원본 필터일 경우, 필터 적용 없이 원본 그대로 할당
        if filter.id == "original" {
            filteredImage = original
            return
        }

        Task {
            do {
                filteredImage = try await applyFilterUseCase.execute(filter: filter, image: original)
            } catch {
                print("필터 적용 실패: \(error.localizedDescription)")
            }
        }
    }
    
    
    
}
