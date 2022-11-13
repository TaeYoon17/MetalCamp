import PlaygroundSupport
import MetalKit

guard let device = MTLCreateSystemDefaultDevice()else {
    fatalError("There is no support GPU")
}
let view = MTKView(frame: CGRect(x: 0, y: 0, width: 600, height: 600), device: device)
view.clearColor = MTLClearColor(red: 1, green: 1, blue: 0.8, alpha: 1)
view.device = device

// set up render pass
guard let drawable = view.currentDrawable,
      let passDescriptor = view.currentRenderPassDescriptor,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else{
    fatalError("There is no command buffer")
}
renderEncoder.setRenderPipelineState(pipelineState)
var vertices: [float3] = [
    [-0.7,  0.8,   1],
    [-0.7, -0.4,   1],
    [ 0.4,  0.2,   1]
]
var matrix = matrix_identity_float4x4
let originBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride * vertices.count, options: [])
renderEncoder.setVertexBuffer(originBuffer,offset: 0,index: 0)
renderEncoder.setFragmentBytes(&lightGrayColor, length: MemoryLayout<float4>.stride, index: 0)
renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)

let angle = Float.pi / 2.0
var distanceVector = float4(vertices.last!.x,vertices.last!.y,vertices.last!.z,1)
var translate = matrix_identity_float4x4
translate.columns.3 = distanceVector

var rotate = matrix_identity_float4x4
rotate.columns.0 = [cos(angle),sin(angle),0,0]
rotate.columns.1 = [-sin(angle),cos(angle),0,0]
matrix = translate * rotate * translate.inverse
// Displace the vertices
vertices = vertices.map {
  let vertex = matrix * float4($0, 1)
  return [vertex.x, vertex.y, vertex.z]
}
var transformedBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<float3>.stride*vertices.count,options: [])
renderEncoder.setVertexBuffer(transformedBuffer, offset: 0, index: 0)
renderEncoder.setFragmentBytes(&redColor, length: MemoryLayout<float4>.stride, index: 0)
renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                             vertexCount: vertices.count)

renderEncoder.endEncoding()

commandBuffer.present(drawable)
commandBuffer.commit()

PlaygroundPage.current.liveView = view
