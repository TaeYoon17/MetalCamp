//
//  Renderer.swift
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/17.
//

import Foundation
import MetalKit
import ModelIO

let MaxOutstandingFrameCount = 3
class Renderer: NSObject{
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let view: MTKView!
    
    var mesh: MTKMesh!
    
    private var renderPipelineStates: MTLRenderPipelineState!
    
    lazy var frameSemaphore: DispatchSemaphore = DispatchSemaphore(value: MaxOutstandingFrameCount)
    lazy var frameIdx = 0
    
    // 동적 그래픽 처리를 위한 버퍼
    private var constantBuffer: MTLBuffer!
    private let constantsSize: Int
    private let constantsStride: Int
    private var currentConstantBufferOffset: Int
    
    private lazy var updateFar: Double = 0
    
    init(device: MTLDevice,view:MTKView) {
        self.device = device
        self.view = view
        self.view.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.constantsSize = MemoryLayout<simd_float4x4>.size
        self.constantsStride = align(constantsSize, upTo: 256)
        self.currentConstantBufferOffset = 0
        
        super.init()
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.view.delegate = self
        
        makeResources()
        makePipeline()
    }
    func makeResources(){
        let allocator = MTKMeshBufferAllocator(device: self.device)
        let mdlMesh = MDLMesh(sphereWithExtent: SIMD3<Float>(0.5, 0.5, 0.5),//크기에 대하여
                              segments: SIMD2<UInt32>(40, 40),
                              inwardNormals: false,
                              geometryType: .lines,
                              allocator: allocator) // MTK에 맞게 적용할 것이란 의미
        let vertexDescriptor: MDLVertexDescriptor = {
           let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.vertexAttributes[0].bufferIndex = 0
            vertexDescriptor.vertexAttributes[0].format = .float3
            vertexDescriptor.vertexAttributes[0].offset = 0
            vertexDescriptor.vertexAttributes[0].name = MDLVertexAttributePosition
            vertexDescriptor.vertexAttributes[1].bufferIndex = 0
            vertexDescriptor.vertexAttributes[1].offset = 12
            vertexDescriptor.vertexAttributes[1].format = .float3
            vertexDescriptor.bufferLayouts[0].stride = 24
            return vertexDescriptor
        }()
        mdlMesh.vertexDescriptor = vertexDescriptor
        
        self.mesh = try! MTKMesh(mesh: mdlMesh, device: device)
        self.constantBuffer = device.makeBuffer(length: constantsStride*MaxOutstandingFrameCount,
                                                options: .storageModeShared)
        self.constantBuffer.label = "Dynamic Constant Buffer"
    }
    func makePipeline(){
        let library = device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        let mtkVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)!
        renderPipelineDescriptor.vertexDescriptor = mtkVertexDescriptor
        do{
            self.renderPipelineStates = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("Is error make pipeline state")
        }
    }
}
extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        self.frameSemaphore.wait()
        updateConstants()
        guard let renderPass = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        commandEncoder.setRenderPipelineState(self.renderPipelineStates)
        
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        // 투영을 어떻게 할 지 설정
        commandEncoder.setVertexBuffer(constantBuffer, offset: currentConstantBufferOffset, index: 2)
        
        for (idx,meshBuffer) in mesh.vertexBuffers.enumerated(){
            commandEncoder.setVertexBuffer(meshBuffer.buffer, offset: meshBuffer.offset, index: idx)
        }
        for submesh in mesh.submeshes{
            //각각 서브메시의 그림을 그릴 설정 값을 정한다.
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
        self.frameIdx = self.frameIdx % MaxOutstandingFrameCount
        commandBuffer.addCompletedHandler { _ in
            self.frameSemaphore.signal()
        }
    }
    func updateConstants(){
        let modelMatrix = matrix_identity_float4x4
        let aspectRatio = Float(self.view.drawableSize.height / self.view.drawableSize.width)
        let canvasWidth: Float = 2
        let canvasHeight = canvasWidth * aspectRatio
        updateFar = (updateFar + 1 / (10 * .pi)) > (2 * .pi) ? 0 : (updateFar + 1 / (10 * .pi))
        let myFar = sin(updateFar)
        let projectionMatrix = simd_float4x4(orthographicProjectionWithLeft: -canvasWidth / 2,
                                             top: canvasHeight / 2,
                                             right: canvasWidth / 2,
                                             bottom: -canvasHeight / 2,
                                             near: -1,
                                             far: Float(myFar))//Float(myFar)
        var transformMaxtrix = projectionMatrix * modelMatrix
        currentConstantBufferOffset = (frameIdx % MaxOutstandingFrameCount) * constantsStride
        let constants = constantBuffer.contents().advanced(by: currentConstantBufferOffset)
        constants.copyMemory(from: &transformMaxtrix, byteCount: constantsSize)
    }
}
