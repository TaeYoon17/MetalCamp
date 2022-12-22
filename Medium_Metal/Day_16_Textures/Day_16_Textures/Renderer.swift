//
//  Renderer.swift
//  Day_16_Textures
//
//  Created by 김태윤 on 2022/12/22.
//

import Foundation
import MetalKit
import simd
import ModelIO
import Dispatch

struct Frame_Node{
    var modelViewProjectionMatrix: float4x4
}

class Renderer:NSObject{
    static let frameMaxCount = 3
    static let objectMaxCount = 12
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let view: MTKView!
    
    var nodes:[Node] = [Node]()
    var boxNode: Node!
    var sphereNode: Node!
    
    private var vertexDescriptor: MTLVertexDescriptor!
    private var renderPipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var samplerState: MTLSamplerState!
    
    private lazy var semaphore = DispatchSemaphore(value: Renderer.frameMaxCount)
    private var frameBuffer: MTLBuffer!
    private var frameIndex: Int = 0
    private var currentFrameOffset: Int = 0
    private var frameSize: Int = 0
    private var frameStride: Int
    private var time:TimeInterval = 0
    
    init(device: MTLDevice,view: MTKView) {
        self.device = device
        self.view = view
        self.commandQueue = device.makeCommandQueue()!
        self.frameSize = MemoryLayout<Frame_Node>.size
        self.frameStride = align(self.frameSize, upTo: 256)
        super.init()
        self.view.device = device
        self.view.delegate = self
        self.view.depthStencilPixelFormat = .depth32Float
        self.view.colorPixelFormat = .bgra8Unorm_srgb
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        
        makeResources()
        makeFrameBuffer()
        makePiepelines()
    }
    func makeResources(){
        var texture: MTLTexture?
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [
            .textureUsage : MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue
        ]
        texture = try? textureLoader.newTexture(name: "uv_grid", scaleFactor: 1.0, bundle: nil,options: options)
        
        //MTKMeshAllocator임으로 주의!!
        let allocator = MTKMeshBufferAllocator(device: device)
        let vertexDescriptor: MDLVertexDescriptor = {
            let descriptor = MDLVertexDescriptor()
            descriptor.vertexAttributes[0].name = MDLVertexAttributePosition
            descriptor.vertexAttributes[0].format = .float3
            descriptor.vertexAttributes[0].offset = 0
            descriptor.vertexAttributes[0].bufferIndex = 0
            descriptor.vertexAttributes[1].name = MDLVertexAttributeNormal
            descriptor.vertexAttributes[1].format = .float3
            descriptor.vertexAttributes[1].offset = 12
            descriptor.vertexAttributes[1].bufferIndex = 0
            descriptor.vertexAttributes[2].name = MDLVertexAttributeTextureCoordinate
            descriptor.vertexAttributes[2].format = .float2
            descriptor.vertexAttributes[2].offset = 24
            descriptor.vertexAttributes[2].bufferIndex = 0
            descriptor.vertexLayouts[0].stride = 32
            return descriptor
        }()
        self.boxNode = {
            let mdlCube = MDLMesh(boxWithExtent: SIMD3<Float>(1.4,1.4,1.4), segments: SIMD3<UInt32>(1,1,1), inwardNormals: false, geometryType: .triangles, allocator: allocator)
            mdlCube.vertexDescriptor = vertexDescriptor
            let cubeMesh = try! MTKMesh(mesh: mdlCube, device: self.device)
            let cube = Node(mesh: cubeMesh)
            cube.texture = texture
            return cube
        }()
        self.sphereNode = {
            let mdlSphere = MDLMesh(sphereWithExtent: SIMD3<Float>(1,1,1), segments: SIMD2<UInt32>(24,24), inwardNormals: false, geometryType: .triangles, allocator: allocator)
            mdlSphere.vertexDescriptor = vertexDescriptor
            let sphereMesh = try! MTKMesh(mesh: mdlSphere, device: self.device)
            let sphere = Node(mesh: sphereMesh)
            sphere.texture = texture
            return sphere
        }()
        self.nodes.append(contentsOf: [boxNode,sphereNode])
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!
    }
    func makeFrameBuffer(){
        self.frameBuffer = device.makeBuffer(length: Renderer.frameMaxCount * Renderer.objectMaxCount * self.frameStride,options: .storageModeShared)
        self.frameBuffer.label = "Dynamic frame buffer"
    }
    func makePiepelines(){
        let library = device.makeDefaultLibrary()!
        let renderPipelineDescriptor = {
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.fragmentFunction = library.makeFunction(name: "fragment_main")!
            descriptor.vertexFunction = library.makeFunction(name: "vertex_main")!
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            descriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
            descriptor.vertexDescriptor = self.vertexDescriptor
            return descriptor
        }()
        let depthDescriptor = {
           let descriptor = MTLDepthStencilDescriptor()
            descriptor.isDepthWriteEnabled = true
            descriptor.depthCompareFunction = .less
            return descriptor
        }()
        let samplerDescriptor = {
            let descriptor = MTLSamplerDescriptor()
            descriptor.normalizedCoordinates = true
            descriptor.magFilter = .linear
            descriptor.minFilter = .linear
            descriptor.mipFilter = .nearest
            descriptor.sAddressMode = .repeat
            descriptor.tAddressMode = .repeat
            return descriptor
        }()
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("renderPipelineState is error")
        }
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)!
        self.samplerState = device.makeSamplerState(descriptor: samplerDescriptor)!
    }
}
extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        semaphore.wait()
        updateFrame()
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else{return}
        
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderCommandEncoder.setRenderPipelineState(self.renderPipelineState)
        
        renderCommandEncoder.setDepthStencilState(self.depthStencilState)
        renderCommandEncoder.setFrontFacing(.counterClockwise)
        renderCommandEncoder.setCullMode(.back)
        
        nodes.enumerated().forEach { (nodeIdx,node) in
            guard let mesh = node.mesh else { return }
            
            let offset = now_frame_obj_offset(objectIdx: nodeIdx, frameIdx: self.frameIndex)
            renderCommandEncoder.setVertexBuffer(frameBuffer, offset: offset, index: 2)
            
            for (i,meshVertexBuffer) in mesh.vertexBuffers.enumerated(){
                renderCommandEncoder.setVertexBuffer(meshVertexBuffer.buffer,
                                                     offset: meshVertexBuffer.offset,
                                                     index: i)
            }
            renderCommandEncoder.setFragmentTexture(node.texture, index: 0)
            renderCommandEncoder.setFragmentSamplerState(samplerState, index: 0)
            for submesh in mesh.submeshes{
                let indexBuffer = submesh.indexBuffer
                
                renderCommandEncoder.drawIndexedPrimitives(
                    type: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: indexBuffer.buffer,
                    indexBufferOffset: indexBuffer.offset)
            }
        }
        
        renderCommandEncoder.endEncoding()
        commandBuffer.present(self.view.currentDrawable!)
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.semaphore.signal()
        }
        commandBuffer.commit()
        self.frameIndex += 1
    }
    func now_frame_obj_offset(objectIdx:Int, frameIdx:Int)->Int{
        let nowFrameOffset = (frameIdx % Renderer.frameMaxCount) * self.frameStride * Renderer.objectMaxCount
        let now_obj_offset = nowFrameOffset + objectIdx * self.frameStride
        return now_obj_offset
    }
    func updateFrame(){
        self.time += (1/Double(view.preferredFramesPerSecond))
        let t = Float(time)
        
        let cameraPosition = SIMD3<Float>(0,0,10)
        let viewMatrix = simd_float4x4(translate: -cameraPosition)
        
        let aspectRatio = Float(self.view.drawableSize.width / self.view.drawableSize.height)
        let projectionMatrix = simd_float4x4(perspectiveProjectionFoVY: .pi/3, aspectRatio: aspectRatio, near: 0.01, far: 100)
        
        let yAxis = SIMD3<Float>(0,0.75,1)
        let rotationMatrix = simd_float4x4(rotateAbout: yAxis, byAngle: t)
        
        boxNode.transform = simd_float4x4(translate: SIMD3<Float>(-2,0,0)) * rotationMatrix
        sphereNode.transform = simd_float4x4(translate: SIMD3<Float>(2,0,0)) * rotationMatrix
        
        nodes.enumerated().forEach{ (nodeIdx,node) in
            let transform = projectionMatrix * viewMatrix * node.worldTransform
            var obj_matrix = Frame_Node(modelViewProjectionMatrix: transform)
            
            let offset = now_frame_obj_offset(objectIdx: nodeIdx, frameIdx: self.frameIndex)
            let objPointer = frameBuffer.contents().advanced(by: offset)
            objPointer.copyMemory(from: &obj_matrix, byteCount: self.frameSize)
        }
    }
}
