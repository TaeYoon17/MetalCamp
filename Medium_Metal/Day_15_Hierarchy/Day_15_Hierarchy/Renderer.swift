//
//  Renderer.swift
//  Day_15_Hierarchy
//
//  Created by 김태윤 on 2022/12/21.
//

import Foundation
import MetalKit
import ModelIO
import simd
import Dispatch

struct NodeFrame{
    let modelViewProjectionMatrix: simd_float4x4
    let color: SIMD4<Float>
}

class Renderer:NSObject{
    static let maxFrameCount: Int = 3
    static let maxObjectCount: Int = 12
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let view: MTKView!
    
    var sunNode: Node!
    var planetNode: Node!
    var moonNode: Node!
    var nodes:[Node] = [Node]()
    private var vertexDescriptor: MTLVertexDescriptor!
    
    private var renderPipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!

    private var frameBuffer: MTLBuffer!
    private var frameStride: Int = 0
    private var frameObjSize: Int = 0
    private var nowFrameIndex:Int = 0
    private var nowFrameOffset: Int = 0
    private var frameSemaphore = DispatchSemaphore(value: Renderer.maxFrameCount)
    private var time: TimeInterval = 0
    init(device: MTLDevice, view: MTKView){
        self.device = device
        self.view = view
        self.commandQueue = device.makeCommandQueue()!
        self.nowFrameIndex = 0
        self.frameObjSize = MemoryLayout<NodeFrame>.size // 하나의 노드에 들어갈 정보만큼 
        self.frameStride = align(frameObjSize, upTo: 256) // 그냥 하나의 객체에 최대한 방을 크게 만든다.
        self.nowFrameOffset = 0
        
        super.init()
        self.view.device = device
        self.view.delegate = self
        self.view.colorPixelFormat = .bgra8Unorm
        self.view.depthStencilPixelFormat = .depth32Float
        
        makeResources()
        makeFrameBuffer()
        makePipeline()
    }
    
    func makeResources(){// MDL 정점 정보는 Normal과 Position만 가져온다.
        let allocator = MTKMeshBufferAllocator(device: device)
        let vertexDescriptor: MDLVertexDescriptor = {
            let descriptor = MDLVertexDescriptor()
            descriptor.vertexAttributes[0].name = MDLVertexAttributePosition
            descriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
            descriptor.vertexAttributes[0].offset = 0
            descriptor.vertexAttributes[1].offset = 12
            descriptor.vertexAttributes[0].format = .float3
            descriptor.vertexAttributes[1].format = .float3
            descriptor.vertexAttributes[0].bufferIndex = 0
            descriptor.vertexAttributes[1].bufferIndex = 0
            descriptor.vertexLayouts[0].stride = 24
            return descriptor
        }()
        
        let mdlSphere = MDLMesh(sphereWithExtent: SIMD3<Float>(1,1,1), segments: SIMD2<UInt32>(24,24), inwardNormals: false, geometryType: .triangles, allocator: allocator)
        mdlSphere.vertexDescriptor = vertexDescriptor
        let sphereMesh = try! MTKMesh(mesh: mdlSphere, device: device)
        self.sunNode = Node(mesh: sphereMesh)
        self.moonNode = Node(mesh: sphereMesh)
        self.planetNode = Node(mesh: sphereMesh)
        
        sunNode.color = SIMD4<Float>(1,1,0,1)
        planetNode.color = SIMD4<Float>(0,0.4,0.9,1)
        moonNode.color = SIMD4<Float>(0.7,0.7,0.7,1)
        sunNode.addChildNode(planetNode)
        planetNode.addChildNode(moonNode)
        nodes.append(contentsOf: [sunNode,planetNode,moonNode])
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!
    }
    func makeFrameBuffer(){
        self.frameBuffer = device.makeBuffer(length: self.frameStride * Renderer.maxFrameCount * Renderer.maxObjectCount)
        self.frameBuffer.label = "Dynamic Constant Buffer"
    }
    func makePipeline(){
        guard let library = device.makeDefaultLibrary() else{
            fatalError("Unable to create default metal library")
        }
        let renderPipelineDescriptor = {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")!
            descriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
            descriptor.vertexDescriptor = self.vertexDescriptor
            
            descriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            return descriptor
        }()
        let depthStencilDescritpror = {
            let descriptor = MTLDepthStencilDescriptor()
            descriptor.isDepthWriteEnabled = true
            descriptor.depthCompareFunction = .less
            return descriptor
        }()
        
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("This is not enabled")
        }
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescritpror)!
    }
    
}
extension Renderer:MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        self.frameSemaphore.wait()
        self.updateFrame()
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(self.renderPipelineState)
        
        renderCommandEncoder.setDepthStencilState(self.depthStencilState)
        renderCommandEncoder.setFrontFacing(.counterClockwise)
        renderCommandEncoder.setCullMode(.back)
        
        
        nodes.enumerated().forEach { (nodeIndex,node) in
            guard let mesh = node.mesh else { return }
            let offset = frameBufferObjOffset(meshIndex: nodeIndex, frameIndex: self.nowFrameIndex)
            renderCommandEncoder.setVertexBuffer(frameBuffer,offset: offset,index: 2)
            print(offset)
            for(i,meshBuffer) in mesh.vertexBuffers.enumerated(){ // 어차피 여기선 노드들의 vertexBuffer는 하나만 존재한다. 반복문이 하나만 돈다는 뜻
                renderCommandEncoder.setVertexBuffer(meshBuffer.buffer, offset: meshBuffer.offset, index: i)
            }
            for submesh in mesh.submeshes{
                let indexBuffer = submesh.indexBuffer
                renderCommandEncoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: indexBuffer.buffer, indexBufferOffset: indexBuffer.offset)
            }
        }
        
        renderCommandEncoder.endEncoding()
        commandBuffer.present(self.view.currentDrawable!)
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.frameSemaphore.signal()
        }
        commandBuffer.commit()
        self.nowFrameIndex += 1
    }
    // 하나의 프레임 버퍼에서 특정 객체를 할당하는 버퍼 크기 할당하기
    func frameBufferObjOffset(meshIndex objectIndex: Int, frameIndex: Int)->Int{
        let nowFrameOffset = (self.nowFrameIndex % Renderer.maxFrameCount) * self.frameStride * Renderer.maxObjectCount
        let nowObjectOffset = nowFrameOffset + (objectIndex * self.frameStride)
        return nowObjectOffset
    }
    func updateFrame(){
        self.time += (1.0/Double(view.preferredFramesPerSecond))
        let t = Float(time)
        
        let cameraPosition = SIMD3<Float>(0,0,10)
        let viewMatrix = simd_float4x4(translate: -cameraPosition)
        
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        let projectionMatrix = simd_float4x4(perspectiveProjectionFoVY: .pi/3, aspectRatio: aspectRatio, near: 0.01, far: 100)
        let yAxis = SIMD3<Float>(0,0,1)
        let planetRadius: Float = 0.3
        let planetOrbitalRadius: Float = 3
        planetNode.transform = simd_float4x4(rotateAbout: yAxis, byAngle: t) * simd_float4x4(translate: SIMD3<Float>(planetOrbitalRadius,0,0)) * simd_float4x4(scale: SIMD3<Float>(repeating: planetRadius))
        
        let moonRadius: Float = 0.25
        let moonOrbitalRadius: Float = 2
        moonNode.transform = simd_float4x4(rotateAbout: yAxis, byAngle: 2 * t) * simd_float4x4(translate: SIMD3<Float>(moonOrbitalRadius,0,0)) * simd_float4x4(scale: SIMD3<Float>(repeating: moonRadius))
        
        nodes.enumerated().forEach { (objectIndex,node) in
            let transform = projectionMatrix * viewMatrix * node.worldTransform
            var constants = NodeFrame(modelViewProjectionMatrix: transform, color: node.color)
            
            let offset = self.frameBufferObjOffset(meshIndex: objectIndex, frameIndex: self.nowFrameIndex)
            let frameBufferPointer = frameBuffer.contents().advanced(by: offset)
            frameBufferPointer.copyMemory(from: &constants, byteCount: frameObjSize)
        }
    }
}
