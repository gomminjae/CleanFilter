//
//  MetalUniformBufferBuilder.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


import Foundation

enum MetalUniformBufferBuilder {
    static func build(from parameters: [String: Float], shader: String) -> [Float] {
        switch shader {
        case "warm_filter":
            return [
                parameters["redBoost"] ?? 0,
                parameters["blueReduce"] ?? 0,
                parameters["saturation"] ?? 1
            ]
        case "cool_filter":
            return [
                parameters["greenBoost"] ?? 0,
                parameters["blueBoost"] ?? 0,
                parameters["saturation"] ?? 1
            ]
        default:
            return []
        }
    }
}
