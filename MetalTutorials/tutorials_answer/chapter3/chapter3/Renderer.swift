//
//  Renderer.swift
//  chapter3
//
//  Created by 김태윤 on 2022/11/03.
//

import Foundation
import MetalKit

class Renderer: NSObject{
    var timer : Float = 0
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var mesh: MTKMesh!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    init(metalView: MTKView){
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else{
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        metalView.device = device
        let mdlMesh = Primitive.makeCube(device: device, size: 1)
        do{
            mesh = try MTKMesh(mesh: mdlMesh, device: device)
        }catch let error{
            fatalError(error.localizedDescription)
        }
        vertexBuffer = mesh.vertexBuffers[0].buffer
        let library = device.makeDefaultLibrary()
        let vertexFn = library?.makeFunction(name: "vertex_main")
        let fragmentFn = library?.makeFunction(name: "fragment_main")
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFn
        pipelineDescriptor.fragmentFunction = fragmentFn
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        do{
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }catch let error{
            fatalError(error.localizedDescription)
        }
        super.init()
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
        metalView.delegate = self
    }
}
extension Renderer:MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    func draw(in view: MTKView) {
        // 1. 명령어 버퍼 생성 및 descriptor 설정
        guard let renderPassdescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassdescriptor) else{
            return
        }
        // 2. 그리기
        timer += 0.05
        var currentTime = sin(timer)
        // 시간 메모리 공간을 ArgumentTable에 할당한다.
        renderEncoder.setVertexBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)
        renderEncoder.setRenderPipelineState(self.pipelineState)
        renderEncoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        for submesh in mesh.submeshes{
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        }
        renderEncoder.endEncoding()
        // 3. 커맨드 큐에 입력
        guard let drawable = view.currentDrawable else{
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        print("draw called")
    }
}
