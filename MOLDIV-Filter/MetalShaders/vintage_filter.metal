//
//  vintage_filter.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/31/25.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float sepiaStrength;
    float brightness;
    float contrast;
};

kernel void vintage_filter(
    texture2d<float, access::read>  inTexture  [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant Uniforms& uniforms               [[buffer(0)]],
    uint2 gid                                [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float4 color = inTexture.read(gid);

    // Step 1: Brightness
    color.rgb += uniforms.brightness;

    // Step 2: Contrast (centered at 0.5)
    color.rgb = ((color.rgb - 0.5) * uniforms.contrast) + 0.5;

    // Step 3: Sepia tone
    float3 sepiaColor;
    sepiaColor.r = dot(color.rgb, float3(0.393, 0.769, 0.189));
    sepiaColor.g = dot(color.rgb, float3(0.349, 0.686, 0.168));
    sepiaColor.b = dot(color.rgb, float3(0.272, 0.534, 0.131));

    color.rgb = mix(color.rgb, sepiaColor, uniforms.sepiaStrength);

    outTexture.write(saturate(color), gid);
}
