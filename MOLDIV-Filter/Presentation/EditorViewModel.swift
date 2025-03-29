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
                filterList = try await loadFilterUseCase.execute()
            } catch {
                print("필터 로딩 실패")
            }
        }
    }
    
    func selectFilter(_ filter: FilterConfig) {
        selectedFilter = filter
        applySelectedFilter()
        
    }
    
    func setOriginalImage(_ image: UIImage) {
        originalImage = image
        filteredImage = image
        
        if let filter = selectedFilter {
            applySelectedFilter()
        }
    }
    private func applySelectedFilter() {
        guard let filter = selectedFilter, let original = originalImage else { return }
        
        Task {
            
            do {
                filteredImage = try await applyFilterUseCase.execute(filter: filter, image: original)
            } catch {
                "\(error.localizedDescription)"
            }
        }
    }
    
}
