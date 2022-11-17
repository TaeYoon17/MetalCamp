//
//  Shader.metal
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/17.
//

#include <metal_stdlib>
using namespace metal;

//struct VertexIn{
//    float2 position [[attribute(0)]];
//    float4 color [[attribute(1)]];
//};
//struct VertexOut{
//    float4 position [[position]];
//    float4 color;
//};
//
//vertex VertexOut vertex_main(VertexIn in [[stage_in]]){
//    VertexOut out{float4(in.position,0,1),in.color};
//    return out;
//}
//
//fragment float4 fragment_main(VertexOut in [[stage_in]]){
//    return in.color;
//}
struct VertexIn{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct VertexOut{
    float4 position [[position]];
    float3 normal;
};
vertex VertexOut vertex_main(VertexIn in [[stage_in]],constant float4x4 &transform [[buffer(2)]]){
    VertexOut out{transform*float4(in.position,1),in.normal};
    return out;
}
fragment float4 fragment_main(VertexOut in [[stage_in]]){
    float3 L = normalize(float3(1,1,1)); // 흰색
    float3 N = normalize(in.normal); // 법선 백터의 크기
    float NdotL = saturate(dot(N, L)); // 내적을 하여 빛의 강도를 결정한다.
    return float4(float3(NdotL),1);
}
