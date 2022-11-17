//
//  Renderer.swift
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/17.
//

import Foundation
import MetalKit


class Renderer: NSObject{
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let view: MTKView!
    var renderPipelineState: MTLRenderPipelineState!
    var vertexBuffer : MTLBuffer!
    var orthoBuffer: MTLBuffer!
    //var mesh: simpleMesh!
    var mtkmesh: SimpleMDLMesh!
    init(device: MTLDevice,view:MTKView) {
        self.device = device
        self.view = view
        self.view.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        makeAspectRatio()
        self.mtkmesh = SimpleMDLMesh(sphereWithExtend: SIMD3<Float>(1,1,1), segments:SIMD2<UInt32>(24,24), device: device)
        makePipeline()
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.view.delegate = self
    }
    func makePipeline(){
        let library = device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        renderPipelineDescriptor.vertexDescriptor = mtkmesh.vertexDescriptor
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("Is error make pipeline state")
        }
    }
}
extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    func draw(in view: MTKView) {
        guard let renderPass = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        for (idx,meshBuffer) in mtkmesh.mesh.vertexBuffers.enumerated(){
            commandEncoder.setVertexBuffer(meshBuffer.buffer, offset: meshBuffer.offset, index: idx)
        }
        commandEncoder.setVertexBuffer(orthoBuffer,offset:0, index: 2)
        for submesh in mtkmesh.mesh.submeshes{
            let indexBuffer:MTKMeshBuffer = submesh.indexBuffer
            commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                 indexCount: submesh.indexCount,
                                                 indexType: submesh.indexType,
                                                 indexBuffer: indexBuffer.buffer,
                                                 indexBufferOffset: indexBuffer.offset)
        }
        commandEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    func makeAspectRatio(){
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        let canvasWidth: Float = 5.0
        let canvasHeight = canvasWidth / aspectRatio
        var projectionMatrix = simd_float4x4(orthographicProjectionWithLeft: -canvasWidth / 2, top: canvasHeight / 2,
                      right: canvasWidth / 2,
                      bottom: -canvasHeight / 2,
                      near: -1,
                      far: 1)
        self.orthoBuffer = device.makeBuffer(bytes: &projectionMatrix, length: MemoryLayout<simd_float4x4>.size,options: .storageModeShared)
    }
}
