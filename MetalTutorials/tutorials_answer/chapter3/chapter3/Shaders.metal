//
//  Shaders.metal
//  chapter3
//
//  Created by 김태윤 on 2022/11/03.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn{
    float4 position [[attribute(0)]];
};
vertex float4 vertex_main(VertexIn vertexIn [[stage_in]],constant float &timer [[buffer(1)]]){
    float4 position = vertexIn.position;
    position.x += timer;
    return position;
}

fragment float4 fragment_main(){
    return float4(0,0,1,1);
}
