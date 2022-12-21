//
//  Renderer.swift
//  Perspective_day_14
//
//  Created by 김태윤 on 2022/12/21.
//

import Foundation
import simd
import MetalKit
import ModelIO
import Dispatch

// Mesh를 담는 공간
struct Node{
    var mesh: MTKMesh
    var modelMatrix: simd_float4x4 = matrix_identity_float4x4
}

class Renderer:NSObject{
    //MARK: -- 최대 프레임과 화면에 객체 설정
    static let MaxCountFrame = 3
    static let MaxObjectCount = 16 // 한 프레임에서 생성할 오브젝트의 개수
    //MARK: -- Metal View 기본 설정
    let view: MTKView!
    let commandQueue: MTLCommandQueue!
    let device: MTLDevice!
    
    //MARK: -- 외부에서 만든 모델들의 설정을 저장하기
    var vertexDescriptor: MTLVertexDescriptor!
    var nodes = [Node]()
    
    //MARK: -- 렌더링 State 기본 설정
    private var renderPipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    
    //MARK: -- 프레임 기본 설정 1, 프레임 버퍼 만들기
    private var frameBuffer: MTLBuffer!
    private let singleFrameSize: Int
    private let frameStrides: Int
    private var currentFrameBufferOffset: Int
    
    private var time: TimeInterval = 0
    private var frameIndex: Int = 0
    private let frameSemaphore: DispatchSemaphore = DispatchSemaphore(value: Renderer.MaxCountFrame)
    
    init(device: MTLDevice, view: MTKView) {
        self.view = view
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        //MARK: -- 연속 동작 프레임 기본 설정
        self.frameIndex = 0
        self.singleFrameSize = MemoryLayout<simd_float4x4>.size
        self.frameStrides = align(singleFrameSize, upTo: 256)
        self.currentFrameBufferOffset = 0
        
        super.init()
        
        self.view.device = device
        self.view.delegate = self
        self.view.colorPixelFormat = .bgra8Unorm
        self.view.depthStencilPixelFormat = .depth32Float
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        
        makeResources()
        makeConstantBuffer()
        makePipeline() // 렌더 파이프라인, 깊이 스텐실
    }
    func makeConstantBuffer(){
        self.frameBuffer = device.makeBuffer(
            length: frameStrides * Renderer.MaxCountFrame * Renderer.MaxObjectCount,options: .storageModeShared)
        self.frameBuffer.label = "Dynamic Constant Buffer"
    }
    func makeResources(){
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlVertexDescriptor: MDLVertexDescriptor = {
           let descriptor = MDLVertexDescriptor()
            descriptor.vertexAttributes[0].name = MDLVertexAttributePosition
            descriptor.vertexAttributes[0].format = .float3
            descriptor.vertexAttributes[0].offset = 0
            descriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
            descriptor.vertexAttributes[1].format = .float3
            descriptor.vertexAttributes[1].offset = 12
            descriptor.vertexAttributes[1].bufferIndex = 0
            descriptor.vertexAttributes[0].bufferIndex = 0
            descriptor.bufferLayouts[0].stride = 24
            return descriptor
        }()
        // 구 만들기
        let mdlSphere = MDLMesh(sphereWithExtent: SIMD3<Float>(1,1,1), segments: SIMD2<UInt32>(24,24),
                                inwardNormals: false, geometryType: .triangles, allocator: allocator)
        mdlSphere.vertexDescriptor = mdlVertexDescriptor
        let sphererMesh = try! MTKMesh(mesh: mdlSphere, device: device)
        // 큐브 만들기
        let mdlCube = MDLMesh(boxWithExtent: SIMD3<Float>(1.3,1.3,1.3), segments: SIMD3<UInt32>(1,1,1),
                              inwardNormals: false, geometryType: .triangles, allocator: allocator)
        mdlCube.vertexDescriptor = mdlVertexDescriptor
        let cubeMesh = try! MTKMesh(mesh: mdlCube, device: device)
        nodes.append(Node(mesh: sphererMesh))
        nodes.append(Node(mesh: cubeMesh))
        vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor)!
    }
    func makePipeline(){
        
        let renderPipelineDescriptor:MTLRenderPipelineDescriptor = {
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            guard let library = device.makeDefaultLibrary() else {
                fatalError("library something error")
            }
            renderPipelineDescriptor.vertexDescriptor = self.vertexDescriptor
            renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
            renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")!
            //MARK: -- 깊이 표현을 위해 추가된 renderPipelineDescriptor의 포맷 설정들
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            renderPipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
            return renderPipelineDescriptor
        }()
        let depthStencilDescriptor: MTLDepthStencilDescriptor = {
            let descriptor = MTLDepthStencilDescriptor()
            descriptor.depthCompareFunction = .less
            descriptor.isDepthWriteEnabled = true
            return descriptor
        }()
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("cannot make render pipeline state \(error)")
        }
        
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
}

extension Renderer:MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        self.frameSemaphore.wait()
        updateFrame()
        guard let renderPassDectriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDectriptor) else {return}
        
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        commandEncoder.setDepthStencilState(self.depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        nodes.enumerated().forEach { (nodeIdx,node) in // 인코더에 offset을 주기
            let mesh = node.mesh // Mesh 정보 가져오기
            commandEncoder.setVertexBuffer(frameBuffer,
                                           offset: frameBufferOffset(objectIndex: nodeIdx, frameIndex: self.frameIndex),
                                           index: 2)
            
            // 여기 이해안감
            for (i,meshBuffer) in mesh.vertexBuffers.enumerated() {
                commandEncoder.setVertexBuffer(meshBuffer.buffer,offset: meshBuffer.offset,index: i)
            }
            for submesh in mesh.submeshes{
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType, indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.frameSemaphore.signal()
        }
        commandBuffer.commit()
        
        frameIndex += 1
    }
    // 세마포어 비동기를 위해서 frameIndex를 파라미터로 받아야한다.
    func frameBufferOffset(objectIndex: Int, frameIndex: Int)->Int{
        let nowFrameOffset = (frameIndex % Renderer.MaxCountFrame) * Renderer.MaxObjectCount * self.frameStrides
        let objectConstantOffset = nowFrameOffset + (objectIndex * self.frameStrides)
        return objectConstantOffset
    }
    func updateFrame(){
        self.time += (1.0 / Double(view.preferredFramesPerSecond)) // 프레임마다 업그레이드하기
        let t:Float = Float(time)
        
        let cameraPosition = SIMD3<Float>(0,0,10)
        let viewMatrix = simd_float4x4(translate: -cameraPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        // 시야각 30도, 비율 화면 비율 1:1, 화면 전체 뷰
        let projectMatrix = simd_float4x4(perspectiveProjectionFoVY: .pi*(3.1/9), aspectRatio: aspectRatio, near: 0.01, far: 100)
        
        let rotationAxis = normalize(SIMD3<Float>(0.3,0.7,0.2))
        let rotationMatrix = simd_float4x4(rotateAbout: rotationAxis, byAngle: t)
        
        nodes[0].modelMatrix = simd_float4x4(translate: SIMD3<Float>(-2,0,0)) * rotationMatrix
        nodes[1].modelMatrix = simd_float4x4(translate: SIMD3<Float>(2,0,0)) * rotationMatrix
        
        nodes.enumerated().forEach { (nodeIdx,node) in
            var transformMatrix = projectMatrix * viewMatrix * node.modelMatrix
            let offset = frameBufferOffset(objectIndex: nodeIdx, frameIndex: frameIndex)
            let nowFrame = frameBuffer.contents().advanced(by: offset)
            nowFrame.copyMemory(from: &transformMatrix, byteCount: singleFrameSize)
        }
    }
}
