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
    init(device: MTLDevice,view:MTKView) {
        self.device = device
        self.view = view
        self.view.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        self.view.clearColor = MTLClearColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        self.view.delegate = self
        makePipeline()
        makeResources()
    }
    func makePipeline(){
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        do{
            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        }catch{
            fatalError("Is error make pipeline state")
        }
    }
    func makeResources(){
        var verteices:[Float] = [
            0,0.5,1,
            -1,-1,1,
            1,-1,1
        ]
        device.makeBuffer(bytes: &verteices, length: MemoryLayout<SIMD>)
    }
}
extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPass = view.currentRenderPassDescriptor else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass)!
        
        
        commandEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
}
