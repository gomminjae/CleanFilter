//
//  ApplyFilterUseCase.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import UIKit


protocol ApplyFilterUseCase {
    func execute(filter: FilterConfig, image: UIImage) async throws -> UIImage
}
