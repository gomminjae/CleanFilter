//
//  DIContainer.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import Foundation
import UIKit

    
final class DIContainer {
    // MARK: - Shared instances
    private lazy var jsonFilterDataSource: JSONFilterDataSource = {
        JSONFilterDataSource()
    }()
    
    private lazy var metalFilterProcessor: ImageFiltering = {
        try! FilterProcessor() 
    }()!
    
    private lazy var filterRepository: FilterRepository = {
        FilterRepositoryImpl(
            jsonDataSource: jsonFilterDataSource,
            filterProcessor: metalFilterProcessor
        )
    }()
    
    // MARK: - UseCases
    
    lazy var loadFiltersUseCase: LoadFilterUseCase = {
        LoadFilterUseCaseImpl(repository: filterRepository)
    }()
    
    lazy var applyFilterUseCase: ApplyFilterUseCase = {
        ApplyFilterUseCaseImpl(repository: filterRepository)
    }()
    
    // MARK: - ViewModels
    
    @MainActor func makeEditorViewModel() -> EditorViewModel {
        EditorViewModel(
            loadFilterUseCase: loadFiltersUseCase,
            applyFilterUseCase: applyFilterUseCase
        )
    }
}
