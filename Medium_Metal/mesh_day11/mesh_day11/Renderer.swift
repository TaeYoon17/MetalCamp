//
//  Renderer.swift
//  mesh_day11
//
//  Created by 김태윤 on 2022/11/15.
//

import Foundation
import MetalKit
class SimpleMesh{
    /// 메시에 들어가는 정보
    /// vertexDescriptor
    /// vertexBuffer
    /// vertexCount
    /// primitiveType
    /// indexBuffer
    /// indexType
    static private var defaultVertexDescriptor : MTLVertexDescriptor{
        let vertexDescriptor = MTLVertexDescriptor()
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
    let vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MTLVertexDescriptor
    let vertexCount: Int
    let primitiveType: MTLPrimitiveType = .triangle
    let indexBuffer: MTLBuffer?
    let indexType: MTLIndexType = .uint16
    let indexCount: Int
    init(vertexBuffers: [MTLBuffer], vertexDescriptor: MTLVertexDescriptor, vertexCount: Int,indexBuffer: MTLBuffer, indexCount: Int)
    {
        self.vertexBuffers = vertexBuffers
        self.vertexDescriptor = vertexDescriptor
        self.vertexCount = vertexCount
        self.indexBuffer = indexBuffer
        self.indexCount = indexCount
    }
    convenience init(planarPolygonSideCount sideCount: Int,
                     radius: Float,
                     color: SIMD4<Float>,
                     device: MTLDevice){
        var positions : [SIMD2<Float>] = []
        var colors : [SIMD4<Float>] = []
        let deltaAngle = (2 * .pi) / Float(sideCount)
        var angle: Float = (.pi / 2)
                for _ in 0..<sideCount{ // 점 좌표를 만들어 놓기
                    positions.append(SIMD2(radius * cos(angle),radius * sin(angle)))
                    colors.append(color)
                    angle += deltaAngle
                }
//        for _ in 0..<sideCount{
//            // 삼각형 점 만들기
//            positions.append(SIMD2(radius * cos(angle),radius * sin(angle)))
//            colors.append(color)
//            positions.append(SIMD2(radius * cos(angle+deltaAngle),radius * sin(angle+deltaAngle)))
//            colors.append(color)
//            positions.append(SIMD2(0,0))
//            colors.append(color)
//            angle += deltaAngle
//        }
        let positionBuffer = device.makeBuffer(bytes: positions,
                                               length: MemoryLayout<SIMD2<Float>>.stride * positions.count,
                                               options: .storageModeShared)!
        let colorBuffer = device.makeBuffer(bytes: colors,
                                            length: MemoryLayout<SIMD4<Float>>.stride * colors.count,
                                            options: .storageModeShared)!
        //        self.init(vertexBuffer: [positionBuffer,colorBuffer],
        //                  vertexDescriptor: SimpleMesh.defaultVertexDescriptor,
        //                  vertexCount: positions.count)
        var indices = [UInt16]()
        let count = UInt16(sideCount)
        for i in 0..<count { // 점 좌표를 이어서 삼각형 만들기
            indices.append(i)
            indices.append(count)
            indices.append((i + 1) % count)
        }
        let indexBuffer = device.makeBuffer(bytes: indices,
                                            length: MemoryLayout<UInt16>.size * indices.count,
                                            options: .storageModeShared)!
        self.init(vertexBuffers: [positionBuffer,colorBuffer], vertexDescriptor: SimpleMesh.defaultVertexDescriptor, vertexCount: positions.count, indexBuffer: indexBuffer, indexCount: indices.count)
    }
}
class Renderer:NSObject{
    let device : MTLDevice!
    let commandQueue: MTLCommandQueue!
    let view: MTKView!
    let mesh: SimpleMesh!
    var renderPipelineState: MTLRenderPipelineState!
    init(_ view: MTKView, _ device:MTLDevice){
        self.view = view
        self.device = device
        commandQueue = device.makeCommandQueue()!
        mesh = SimpleMesh(planarPolygonSideCount: 10,
                          radius: 0.5,
                          color: SIMD4<Float>(0.0, 0.5, 0.8, 1.0),
                          device: self.device)
        view.device = device
        super.init()
        view.delegate = self
        view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.makePipeline()
    }
    func makePipeline(){
        let library = device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = self.view.colorPixelFormat
        renderPipelineDescriptor.vertexDescriptor = mesh.vertexDescriptor
        do{
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("state init error")
        }
        
    }
    func makeResources(){
        
    }
}
extension Renderer:MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        for (idx,buffer) in self.mesh.vertexBuffers.enumerated(){
            commandEncoder.setVertexBuffer(buffer, offset: 0, index: idx)
        }
//        commandEncoder.drawPrimitives(type: mesh.primitiveType,
//                                      vertexStart: 0,
//                                      vertexCount: mesh.vertexCount)
        if let indexBuffer = mesh.indexBuffer {
            commandEncoder.drawIndexedPrimitives(type: mesh.primitiveType,
                                                       indexCount: mesh.indexCount,
                                                       indexType: mesh.indexType,
                                                       indexBuffer: indexBuffer,
                                                       indexBufferOffset: 0)
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
        //        commandBuffer.addCompletedHandler { cmdBuffer in
        //            print("is Finished")
        //        }
    }
}
