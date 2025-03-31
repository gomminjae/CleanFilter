//
//  FilterRepository.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import UIKit

protocol FilterRepository {
    func loadFilterList() async throws -> [FilterConfig]
    func applyFilter(_ filter: FilterConfig, to image: UIImage) async throws -> UIImage
}
