//
//  simpleMesh.swift
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/17.
//
//View와의 상호작용이 없기 때문에 Metal만 import해도 된다.
import Foundation
import Metal
typealias d2 = (x:Float,y:Float)
class simpleMesh{
    static private var defaultVertexDescriptor: MTLVertexDescriptor{
        let vertexDescriptor:MTLVertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.layouts[1].stride = MemoryLayout<SIMD4<Float>>.stride
        return vertexDescriptor
    }
    /// 이전엔 하나의 MTML 버퍼에 색과 위치 정보를 모두 넣었지만
    /// 이젠 각각의 정보에 따라 버퍼공간을 따로 할당한다
    let vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    let vertexCount: Int
    let primitiveType: MTLPrimitiveType = .triangle
    init(vertexBuffers: [MTLBuffer], vertexDescriptor: MTLVertexDescriptor, vertexCount: Int)
    {
        self.vertexBuffers = vertexBuffers
        self.vertexDescriptor = vertexDescriptor
        self.vertexCount = vertexCount
    }
    convenience init(positions:[d2],color:SIMD4<Float>,device: MTLDevice){
        var simdPositions: [SIMD2<Float>] = positions.map { (x: Float, y: Float) in SIMD2<Float>(x: x, y: y) }
        var simdColors:[SIMD4<Float>] = Array(repeating: color, count: simdPositions.count)
        
        let positionBuffer = device.makeBuffer(bytes:&simdPositions,
                                               length: MemoryLayout<SIMD2<Float>>.stride * simdPositions.count,
                                               options: .storageModeShared)!
        let colorBuffer = device.makeBuffer(bytes:&simdColors,
                                            length: MemoryLayout<SIMD2<Float>>.stride * simdColors.count,
                                            options: .storageModeShared)!
        self.init(vertexBuffers:[positionBuffer,colorBuffer],vertexDescriptor: simpleMesh.defaultVertexDescriptor,vertexCount: positions.count)
    }
}
