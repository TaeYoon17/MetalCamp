//
//  Renderer.swift
//  2d_math_day10
//
//  Created by 김태윤 on 2022/11/14.
//

import Foundation
import MetalKit

struct FrameBuffer{
    private let MaximumFrameCount: Int
    var buffer: MTLBuffer!
    let strideSize: Int
    let dataSize: Int
    var nowFrameIndex: Int = 0
    var nowOffset: Int{
        get{
            return self.nowFrameIndex * self.strideSize
        }
    }
    init(device: MTLDevice,MaximumFrameCount: Int,StrideSize: Int,DataSize: Int){
        self.strideSize = StrideSize
        self.dataSize = DataSize
        self.MaximumFrameCount = MaximumFrameCount
        self.buffer = device.makeBuffer(length: StrideSize * MaximumFrameCount,options: .storageModeShared)!
    }
    mutating func setNextFrame(){
        self.nowFrameIndex = (nowFrameIndex + 1) % MaximumFrameCount
    }
    mutating func insertFrameData<T>(data: inout T){
        let nowOffsetPointer:UnsafeMutableRawPointer = self.buffer.contents().advanced(by: self.nowOffset)
        nowOffsetPointer.copyMemory(from: &data, byteCount: self.dataSize)
    }
}

class Renderer:NSObject{
    static let MaximunFrameCount = 3
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let view: MTKView
    private var vertexBuffer : MTLBuffer!
    private var renderPipelineState: MTLRenderPipelineState!
    // Dynamic Constant 구성
    var framebuffer: FrameBuffer!
    let frameSemaphore : DispatchSemaphore!
    var time : TimeInterval = 0.0
    var verticies: [SIMD4<Float>] = [
        SIMD4<Float>(-0.4,  0.4,0,1),
        SIMD4<Float>( 0.4, -0.8,0,1),
        SIMD4<Float>(0.8,  0.8,0,1),
    ]
    init(_ device: MTLDevice, _ view: MTKView) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        self.vertexBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * 6, options: .storageModeShared)
        self.view.device = self.device
        self.framebuffer = FrameBuffer(device: self.device,
                                             MaximumFrameCount: Renderer.MaximunFrameCount,
                                             StrideSize: 256,
                                        DataSize: MemoryLayout<simd_float4x4>.size)
        self.frameSemaphore = DispatchSemaphore(value: Renderer.MaximunFrameCount)
        super.init()
        self.view.delegate = self
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.makePipeline()
        self.makeResources()
    }
}

extension Renderer{
    func makePipeline(){
        let vertexDescriptor : MTLVertexDescriptor = {
            let temp = MTLVertexDescriptor()
            temp.attributes[0].format = .float2
            temp.attributes[0].offset = 0
            temp.attributes[0].bufferIndex = 0
            temp.attributes[1].format = .float4
            temp.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
            temp.attributes[1].bufferIndex = 0
            temp.layouts[0].stride = MemoryLayout<Float>.stride * 6
            return temp
        }()
        let pipelineDescriptor: MTLRenderPipelineDescriptor = {
           let temp = MTLRenderPipelineDescriptor()
            guard let library = device.makeDefaultLibrary()else {
                fatalError("This device doesn't support library")
            }
            temp.vertexFunction = library.makeFunction(name: "vertex_main")!
            temp.fragmentFunction = library.makeFunction(name: "fragment_main")!
            temp.vertexDescriptor = vertexDescriptor
            temp.colorAttachments[0].pixelFormat = self.view.colorPixelFormat
            return temp
        }()
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }catch{
            fatalError("This device doesn't support renderpipeline")
        }
    }
    func makeResources(){
        var verticies: [Float] = [
            -0.4 * 400,  0.4 * 400, 1.0, 0.0, 1.0, 1.0, // 하나의 버퍼에 담을 값
            0.4 * 400, -0.8 * 400, 0.0, 1.0, 1.0, 1.0,
            0.8 * 400,  0.8 * 400, 1.0, 1.0, 0.0, 1.0,
        ]
        self.vertexBuffer = device.makeBuffer(bytes: &verticies,
                                              length: MemoryLayout<Float>.stride * verticies.count,
                                              options: .storageModeShared)
    }
}

extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        self.frameSemaphore.wait()
        updateFrames()
        guard let renderPassDescriptor = self.view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        let commandEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        commandEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(self.framebuffer.buffer,offset:self.framebuffer.nowOffset, index:1)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        commandEncoder.endEncoding()
        
        commandBuffer.present(self.view.currentDrawable!)
        commandBuffer.commit()
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.frameSemaphore.signal()
        }
        self.framebuffer.setNextFrame()
    }
    
    func updateFrames(){
        //변할 값 설정하기
        self.time += 1.0 / Double(view.preferredFramesPerSecond) // 1 프레임만큼 시간 증가
        let t: Float = Float(time)
        let scaleMatrix: simd_float4x4 =  {
            let scaleRate:Float = 1.5
            let scaleScala = 1.0 + 0.5 * cos(scaleRate * t)
            print(scaleScala)
            let scale = SIMD2<Float>(scaleScala,scaleScala)
            return simd_float4x4(scale2D: scale)
        }()
        let rotateMatrix: simd_float4x4 = {
            let rotateRate: Float = 2.5
            let rotateAngle = rotateRate * t
            return simd_float4x4(rotateZ: rotateAngle)
        }()
        let translateMatrix: simd_float4x4 = {
            let orbitalRadius: Float = 200
            let translation:SIMD2<Float> = orbitalRadius * SIMD2<Float>(cos(t), sin(t))
            return simd_float4x4(translate2D: translation)
        }()
        var modelMatrix =  rotateMatrix * scaleMatrix * translateMatrix
        let projectionMatrix = {
            let aspectRatio:Float = Float(view.drawableSize.width / view.drawableSize.height)
            let canvasWidth:Float = 800
            let canvasHeight:Float = 800
            return simd_float4x4(orthographicProjectionWithLeft: -canvasWidth / 2,
                                 top: canvasHeight / 2,
                                 right: canvasWidth / 2,
                                 bottom: -canvasHeight / 2,
                                 near: 0,
                                 far: 1)
        }()
        print("Projection",projectionMatrix)
        var transformMatrix:simd_float4x4 = projectionMatrix * modelMatrix
        self.verticies.forEach { val in
            print(projectionMatrix * val)
        }
        
        let nowOffsetPointer = self.framebuffer.buffer.contents().advanced(by: self.framebuffer.nowOffset)
        
        nowOffsetPointer.copyMemory(from: &transformMatrix, byteCount: self.framebuffer.dataSize)
        
    }
     
//    func updateFrames(){
//        //변할 값 설정하기
//        let time = CACurrentMediaTime()
//        let speedFactor = 3.0
//        let rotationAngle = Float(fmod(speedFactor * time, .pi * 2))
//        let rotationMagnitude: Float = 0.1
//        //var positionOffset: SIMD2<Float> = rotationMagnitude * SIMD2<Float>(cos(rotationAngle),sin(rotationAngle))
//        var positionOffset: simd_float4x4 = simd_float4x4.getIdentity()
//        // 값을 상수 버퍼에 넣어두기
//        framebuffer.insertFrameData(data: &positionOffset)
//    }
}
