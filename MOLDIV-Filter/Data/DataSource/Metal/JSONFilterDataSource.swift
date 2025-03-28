//
//  JSONFilterDataSource.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//

import Foundation

enum JsonFilterDataSourceError: Error {
    case notFound
}

protocol FilterDataSource {
    func loadFilters() async throws -> [FilterConfig]
}

final class JSONFilterDataSource: FilterDataSource {
    
    private let subDirectory: String
    
    init(subdirectory: String = "") {
        self.subDirectory = subdirectory
    }
    
    func loadFilters() async throws -> [FilterConfig] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subDirectory) else {
            throw JsonFilterDataSourceError.notFound
        }
        
        var configs: [FilterConfig] = []
        
        try await withThrowingTaskGroup(of: FilterConfig?.self) { group in
            for url in urls {
                group.addTask {
                    do {
                        let data = try Data(contentsOf: url)
                        return try JSONDecoder().decode(FilterConfig.self, from: data)
                    } catch {
                        print("디코딩 오류: \(url.lastPathComponent)|||\(error)")
                        return nil
                    }
                }
            }
            
            for try await result in group {
                if let config = result {
                    configs.append(config)
                }
            }
        }
        
        return configs
    }
    
    
    
    
    
}
