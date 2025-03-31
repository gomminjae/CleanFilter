//
//  FilterConfig.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/28/25.
//

import Foundation

struct FilterConfig: Codable {
    
    let id: String
    let name: String
    let shader: String
    let thumbnail: String
    let parameters: [String: Float]
    
    public init(id: String, name: String, shader: String, thumbnail: String, parameters: [String : Float]) {
        self.id = id
        self.name = name
        self.shader = shader
        self.thumbnail = thumbnail
        self.parameters = parameters
    }
    
}
