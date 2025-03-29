//
//  ApplyFilterUseCaseImpl.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import UIKit
import Foundation



final class ApplyFilterUseCaseImpl: ApplyFilterUseCase {
    
    private let repository: FilterRepository
    
    init(repository: FilterRepository) {
        self.repository = repository
    }
    
    
    func execute(filter: FilterConfig, image: UIImage) async throws -> UIImage {
        try await repository.applyFilter(filter, to: image)
    }
    
    
}
