//
//  Uniforms.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//


#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float greenBoost;
    float blueBoost;
    float saturation;
};

kernel void cool_filter(
    texture2d<float, access::read> inTexture [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    constant Uniforms& uniforms [[ buffer(0) ]],
    uint2 gid [[ thread_position_in_grid ]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;

    float4 color = inTexture.read(gid);
    color.g += uniforms.greenBoost;
    color.b += uniforms.blueBoost;
    color.rgb *= uniforms.saturation;
    
    color = saturate(color);
    
    outTexture.write(color, gid);
}
