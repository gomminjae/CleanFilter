//
//  MetalUniformBufferBuilder.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


import Foundation

struct MetalUniformBufferBuilder {
    static func build(from parameters: [String: Float]) -> [Float] {
        // 파라미터를 알파벳 순서로 정렬하여 항상 동일한 순서 보장
        let sortedKeys = parameters.keys.sorted()
        return sortedKeys.map { parameters[$0] ?? 0 }
    }
}
