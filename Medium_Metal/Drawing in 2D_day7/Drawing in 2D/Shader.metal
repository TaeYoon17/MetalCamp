//
//  Shader.metal
//  Drawing in 2D
//
//  Created by 김태윤 on 2022/11/13.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertex_main(device float2 const* myVertex [[buffer(0)]],uint vertexID [[vertex_id]]){
    float2 position = myVertex[vertexID];
    return float4(position,0,1);
}
fragment float4 fragment_main(float4 position [[stage_in]]){
    return float4(1,0.0,0.0,1);
}
