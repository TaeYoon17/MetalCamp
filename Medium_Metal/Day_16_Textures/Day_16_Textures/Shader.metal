//
//  Shader.metal
//  Day_16_Textures
//
//  Created by 김태윤 on 2022/12/22.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};
struct VertexOut{
    float4 position [[position]];
    float3 normal;
    float2 texCoords;
};

struct node_obj{
    float4x4 modelViewProjectionMatrix;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant node_obj &obj [[buffer(2)]]){
    VertexOut out;
    out.position = obj.modelViewProjectionMatrix * float4(in.position,1.0);
    out.normal = in.normal;
    out.texCoords = in.texCoords;
    return out;
}
fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float, access::sample> textureMap [[texture(0)]],
                              sampler textureSampler [[sampler(0)]]){
    float4 color = textureMap.sample(textureSampler,in.texCoords);
    // textureSampler => 텍스처 매핑에 이용할 도구
    // textureMap => 텍스처 매핑에 이용할 텍스처
    // texCoords => 이 정점에 맞는 텍스처 위치
    return color;
}
