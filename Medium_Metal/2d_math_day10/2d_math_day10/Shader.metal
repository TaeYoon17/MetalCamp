//
//  Shader.metal
//  2d_math_day10
//
//  Created by 김태윤 on 2022/11/14.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut{
    float4 position [[position]];
    float4 color;
};

struct VertexIn{
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],constant float4x4& transform [[buffer(1)]]){
    float4 inPosition = float4(in.position,0,1);
    float4 outPosition = transform * inPosition;
    VertexOut out {outPosition,in.color};
    return out;
}
fragment float4 fragment_main(VertexOut in [[stage_in]]){
    return in.color;
}
