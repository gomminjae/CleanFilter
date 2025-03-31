//
//  MetalUniformBufferBuilder.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


import Foundation

struct MetalUniformBufferBuilder {
    
    // 🧠 셰이더 이름 → uniform 키 순서
    private static let shaderUniformMap: [String: [String]] = [
        "warm_filter": ["redBoost", "blueReduce", "saturation"],
        "cool_filter": ["blueBoost", "greenBoost", "saturation"],
        "vintage_filter": ["sepiaStrength", "brightness", "contrast"],
        "dreamy_filter": ["brightness", "saturation", "contrast", "blueBoost"]
        // 🔧 새로운 필터 추가 시 여기에만 추가
    ]
    
    static func build(from parameters: [String: Float], shader: String) -> [Float] {
        guard let keys = shaderUniformMap[shader] else {
            print("⚠️ 해당 셰이더 이름에 대한 uniform key 매핑 없음: \(shader)")
            return []
        }

        return keys.map { parameters[$0] ?? 0.0 }
    }
}
