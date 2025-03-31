//
//  FilterRepositoryImpl.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import UIKit

final class FilterRepositoryImpl: FilterRepository {
    
    private let jsonDataSource: JSONFilterDataSource
    private let filterProcessor: ImageFiltering
    
    init(jsonDataSource: JSONFilterDataSource, filterProcessor: ImageFiltering) {
        self.jsonDataSource = jsonDataSource
        self.filterProcessor = filterProcessor
    }
    
    
    
    func loadFilterList() async throws -> [FilterConfig] {
        try await jsonDataSource.loadFilters()
    }
    
    func applyFilter(_ filter: FilterConfig, to image: UIImage) async throws -> UIImage {
        try filterProcessor.apply(filter: filter, to: image)
    }
    
    
}
