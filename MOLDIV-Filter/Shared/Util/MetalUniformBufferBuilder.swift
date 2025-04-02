//
//  MetalUniformBufferBuilder.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


import Foundation

struct MetalUniformBufferBuilder {
    
    private static let shaderUniformMap: [String: [String]] = [
        "warm_filter": ["redBoost", "blueReduce", "saturation"],
        "cool_filter": ["blueBoost", "greenBoost", "saturation"],
        "vintage_filter": ["sepiaStrength", "brightness", "contrast"],
        "dreamy_filter": ["brightness", "saturation", "contrast", "blueBoost"]
        
    ]
    
    static func build(from parameters: [String: Float], shader: String) -> [Float] {
        guard let keys = shaderUniformMap[shader] else {
            print("uniform key 매핑 없음: \(shader)")
            return []
        }

        return keys.map { parameters[$0] ?? 0.0 }
    }
}
