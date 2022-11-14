//
//  Shader.metal
//  Drawing in 2D
//
//  Created by 김태윤 on 2022/11/13.
//
// 정점 값은 단지 위치만 알고 있으면 안된다.
// 빛 반사를 위해선 노말 벡터 값을 알아야한다.
// 표면에 텍스쳐를 입히기 위해선, 정점 위치와는 조금 다른 텍스쳐 위치를 갖고 있어야 한다.
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
// Day 6 vertex shader
//vertex float4 vertex_main(device float2 const* verticies [[buffer(0)]],uint vertexID [[vertex_id]]){
//    float2 position = verticies[vertexID];
//    return float4(position,0,1);
//}
// *를 없애서 버퍼의 모든 데이터를 가져오는 것이 아니라 layout으로 설정한 만큼만 가져옴
// Day 8 vertex Shader
//vertex VertexOut vertex_main(VertexIn in [[stage_in]]){
//    VertexOut out {float4(in.position,0,1),in.color};
//    return out;
//}
vertex VertexOut vertex_main(VertexIn in [[stage_in]],constant float2 &positionOffset [[buffer(1)]]){
    VertexOut out {float4(in.position+positionOffset,0,1),in.color};
    return out;
}
fragment float4 fragment_main(VertexOut in [[stage_in]]){
    return in.color;
}
