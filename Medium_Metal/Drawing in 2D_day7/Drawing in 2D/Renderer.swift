//
//  Renderer.swift
//  Drawing in 2D
//
//  Created by 김태윤 on 2022/11/13.
//

import Foundation
import MetalKit

class Renderer: NSObject,MTKViewDelegate{
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let view: MTKView
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    init(device: MTLDevice,view: MTKView){
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        self.view = view
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
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
           fatalError("renderPipelineState makes error!!")
        }
    }
    func makeResources(){
        var positions: [SIMD2<Float>] = [
            (-0.8,-0.4),
            (0.4,-0.8),
            (0.8,0.8)
        ].map{SIMD2<Float>($0.0,$0.1)}
        self.vertexBuffer = device.makeBuffer(bytes: &positions,
                                              length: MemoryLayout<SIMD2<Float>>.stride * positions.count,
                                              options: .storageModeShared)
        //let aa:UnsafeMutablePointer<SIMD2<Float>> = vertexBuffer.contents().assumingMemoryBound(to: SIMD2<Float>.self)
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor: MTLRenderPassDescriptor = self.view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(self.renderPipelineState)
        commandEncoder.setVertexBuffer(self.vertexBuffer,offset: 0,index: 0)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        commandEncoder.endEncoding()
        
        commandBuffer.present(self.view.currentDrawable!)
        commandBuffer.commit()
    }
}
