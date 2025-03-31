//
//  LoadFilterUseCaseImpl.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


final class LoadFilterUseCaseImpl: LoadFilterUseCase {
    private let repository: FilterRepository

    init(repository: FilterRepository) {
        self.repository = repository
    }

    func execute() async throws -> [FilterConfig] {
        try await repository.loadFilterList()
    }
}
