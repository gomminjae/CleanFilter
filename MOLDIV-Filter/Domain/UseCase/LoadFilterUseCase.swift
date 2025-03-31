//
//  LoadFilterUseCase.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import Foundation

protocol LoadFilterUseCase {
    func execute() async throws -> [FilterConfig]
}
