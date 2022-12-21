//
//  File.metal
//  Day_15_Hierarchy
//
//  Created by 김태윤 on 2022/12/21.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};
struct VertexOut{
    float4 position [[position]];
    float3 normal;
    float4 color;
};

struct frameNodeObject{
    float4x4 modelViewProjectionMatrix;
    float4 color;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],constant frameNodeObject& object [[buffer(2)]]){
    VertexOut out;
    out.position = object.modelViewProjectionMatrix * float4(in.position,1);
    out.normal = in.normal;
    out.color = object.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]){
    return in.color;
}
