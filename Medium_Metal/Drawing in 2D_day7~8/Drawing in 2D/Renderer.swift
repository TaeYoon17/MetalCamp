//
//  Renderer.swift
//  Drawing in 2D
//
//  Created by 김태윤 on 2022/11/13.
//

import Foundation
import MetalKit
let MaxOutstandingFrameCount = 3
class Renderer: NSObject,MTKViewDelegate{
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let view: MTKView
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    //Day 9 FrameIndex 구현
    private var frameIndex: Int // 사용할 현재 프레임 번호
    private var constantsBuffer: MTLBuffer! // 프레임 공간
    private let constantsSize: Int // 실제 프레임에서 사용하는 공간
    private let constantsStride: Int //프레임 별 GPU 가용공간
    private var constantsBufferOffset: Int // 버퍼에서 프레임 공간의 가장 앞 인덱스
    // 데이터 간 동기화를 위한 세마포어 (같은 프레임 공간 동시에 접근하는 것을 막기 위해)
    private var frameSemaphore = DispatchSemaphore(value: MaxOutstandingFrameCount)
    init(device: MTLDevice,view: MTKView){
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
        //상수 프레임 관련 기본 설정
        self.frameIndex = 0
        self.constantsSize = MemoryLayout<SIMD2<Float>>.size
        self.constantsStride = 256
        self.constantsBufferOffset = 0
        super.init()
        self.view.device = self.device
        self.view.delegate = self
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        makePipeline()
        makeResources()
    }
    func makePipeline(){
        let library = device.makeDefaultLibrary()!
        let vertexFn = library.makeFunction(name: "vertex_main")!
        let fragmentFn = library.makeFunction(name: "fragment_main")!
        let renderPipelineDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFn
        renderPipelineDescriptor.fragmentFunction = fragmentFn
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        // 정점 구조 만들기, bufferIndex가 모두 같은 곳에 위치
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        // 정점에 대한 정보 msl에서 stage_in 영역에 여기에 설정한 만큼의 크기씩 가져다 놓게 설정함
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 6
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
           fatalError("renderPipelineState makes error!!")
        }
    }
    func makeResources(){
//        var positions: [SIMD2<Float>] = [
//            (-0.8,-0.4),
//            (0.4,-0.8),
//            (0.8,0.8)
//        ].map{SIMD2<Float>($0.0,$0.1)}
//        self.vertexBuffer = device.makeBuffer(bytes: &positions,
//                                              length: MemoryLayout<SIMD2<Float>>.stride * positions.count,
//                                              options: .storageModeShared)
        var vertexData: [Float] = [// x,y,r,g,b,a
            -0.8,  0.4, 1.0, 0.0, 1.0, 1.0, // 하나의 버퍼에 담을 값
            0.4, -0.8, 0.0, 1.0, 1.0, 1.0,
            0.8,  0.8, 1.0, 1.0, 0.0, 1.0,
        ]// 6(one vertex data) * 3(vertex) * 4 (float byte) = 72byte
        self.vertexBuffer = device.makeBuffer(bytes: &vertexData, length: MemoryLayout<Float>.stride * vertexData.count,
                                              options: .storageModeShared)
        // 상수 버퍼를 만든다.
        self.constantsBuffer = device.makeBuffer(length: constantsStride * MaxOutstandingFrameCount, options: .storageModeShared)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        self.frameSemaphore.wait()
        self.updateConstants()// 버퍼 오프셋과 다른 값도 모두 변하기 때문에 무조건 앞으로 나와야 한다.
        guard let renderPassDescriptor: MTLRenderPassDescriptor = self.view.currentRenderPassDescriptor else {return}
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        commandEncoder.setVertexBuffer(self.vertexBuffer,offset: 0,index: 0) // 쉐이더로 MTLBuffer 값을 전송한다.
        commandEncoder.setVertexBuffer(self.constantsBuffer,offset: self.constantsBufferOffset, index: 1)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        commandEncoder.endEncoding()
        
        commandBuffer.present(self.view.currentDrawable!)
        commandBuffer.commit()
        commandBuffer.addCompletedHandler { [weak self] _ in
            // 세마포어 빠져나가기
            self?.frameSemaphore.signal()
        }
        frameIndex = (frameIndex + 1 ) % MaxOutstandingFrameCount
    }
    func updateConstants(){
        //변할 값 설정하기
        let time = CACurrentMediaTime()
        let speedFactor = 3.0
        let rotationAngle = Float(fmod(speedFactor * time, .pi * 2))
        let rotationMagnitude: Float = 0.1
        var positionOffset = rotationMagnitude * SIMD2<Float>(cos(rotationAngle),sin(rotationAngle))
        
        // 값을 상수 버퍼에 넣어두기
        self.constantsBufferOffset = frameIndex * constantsStride
        let constants:UnsafeMutableRawPointer = constantsBuffer.contents().advanced(by: constantsBufferOffset)
        constants.copyMemory(from: &positionOffset, byteCount: constantsSize)
    }
}
