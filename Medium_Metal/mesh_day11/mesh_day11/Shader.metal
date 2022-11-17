//
//  Shader.metal
//  mesh_day11
//
//  Created by 김태윤 on 2022/11/15.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};
struct VertexOut{
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]){
    VertexOut out {float4(in.position,0,1),in.color};
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]){
    return in.color;
}
