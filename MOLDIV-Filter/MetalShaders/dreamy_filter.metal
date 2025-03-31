//
//  dreamy_filter.metal
//  MOLDIV-Filter
//
//  Created by 권민재 on 4/1/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void dreamy_filter(
    texture2d<float, access::read> inTexture  [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    constant float* uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float4 color = inTexture.read(gid);

    float brightness = uniforms[0];
    float saturation = uniforms[1];
    float contrast = uniforms[2];
    float blueBoost = uniforms[3];

    // Step 1: brightness
    color.rgb += brightness;

    // Step 2: contrast
    color.rgb = ((color.rgb - 0.5) * contrast) + 0.5;

    // Step 3: saturation
    float gray = dot(color.rgb, float3(0.299, 0.587, 0.114));
    color.rgb = mix(float3(gray), color.rgb, saturation);

    // Step 4: slight blue push
    color.b += blueBoost;

    outTexture.write(saturate(color), gid);
}
