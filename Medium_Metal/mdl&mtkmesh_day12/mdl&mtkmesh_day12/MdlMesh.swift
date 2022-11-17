//
//  MdlMesh.swift
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/17.
//

import Foundation
import MetalKit
extension MDLVertexDescriptor {
    var vertexAttributes: [MDLVertexAttribute] {
        return attributes as! [MDLVertexAttribute]
    }
    var bufferLayouts: [MDLVertexBufferLayout] {
        return layouts as! [MDLVertexBufferLayout]
    }
}
class SimpleMDLMesh:NSObject{
    static private var mdl_defaultVertexDescriptor:MDLVertexDescriptor{
        let vertexDescriptor:MDLVertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
        vertexDescriptor.vertexAttributes[0].bufferIndex = 0
        vertexDescriptor.vertexAttributes[0].offset = 0
        vertexDescriptor.vertexAttributes[0].format = .float3
        vertexDescriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
        vertexDescriptor.vertexAttributes[1].bufferIndex = 0
        vertexDescriptor.vertexAttributes[1].offset = 12
        vertexDescriptor.vertexAttributes[1].format = .float3
        vertexDescriptor.bufferLayouts[0].stride = 24
        return vertexDescriptor
    }
    var mesh: MTKMesh!
    var vertexDescriptor: MTLVertexDescriptor!
    var allocator : MDLMeshBufferAllocator!
    init(mdlMesh: MDLMesh,device: MTLDevice,allocator: MTKMeshBufferAllocator){
        self.allocator = allocator
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        do{
            self.mesh = try MTKMesh(mesh: mdlMesh, device: device)
        }catch{
            fatalError("mesh init error")
        }
        super.init()
    }
    convenience init(sphereWithExtend extent:SIMD3<Float>,segments:SIMD2<UInt32>,device: MTLDevice){
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(sphereWithExtent: extent, segments: segments, inwardNormals: false, geometryType: .triangles, allocator: allocator)
        self.init(mdlMesh:mdlMesh,device: device,allocator: allocator)
    }
}
