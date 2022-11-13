import Cocoa
import Metal

let device = MTLCreateSystemDefaultDevice()!
let library = device.makeDefaultLibrary()!
let commandQueue = device.makeCommandQueue()!

let kernelFunction = library.makeFunction(name: "add_two_values")!

let computePipeline: MTLComputePipelineState = try device.makeComputePipelineState(function: kernelFunction)

// 총 32개 쓰레드 사용 1차원 배열
let threadsPerThreadgroup: MTLSize = MTLSize(width: 32, height: 1, depth: 1)
// 하나의 그룹당 8개 쓰레드 사용
let threadgroupCount: MTLSize = MTLSize(width: 8, height: 1, depth: 1)

let elementCount = 256
// MTLBuffer는 인덱서 지원하지 않음
let inputBufferA: MTLBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * elementCount,
                                     options: .storageModeShared)!
let inputBufferB: MTLBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * elementCount,
                                     options: .storageModeShared)!
let outputBuffer: MTLBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride * elementCount,
                                     options: .storageModeShared)!
/// UnsafeMutablePointer는 인덱서, 서브스크립팅을 지원한다.
/// 실제 C언어의 배열과 매우 같은 구조
/// Accesses the pointee at the specified offset from this pointer.
///
/// For a pointer `p`, the memory at `p + i` must be initialized when reading
/// the value by using the subscript. When the subscript is used as the left
/// side of an assignment, the memory at `p + i` must be initialized or
/// the pointer's `Pointee` type must be a trivial type.
let inputsA: UnsafeMutablePointer<Float> = inputBufferA.contents().assumingMemoryBound(to: Float.self)
let inputsB: UnsafeMutablePointer<Float> = inputBufferB.contents().assumingMemoryBound(to: Float.self)
for i in 0..<elementCount{

    inputsA[i] = Float(i)
    inputsB[i] = Float(elementCount - i)
}

let commandBuffer = commandQueue.makeCommandBuffer()!
commandBuffer.addCompletedHandler { _ in
    let outputs:UnsafeMutablePointer<Float> = outputBuffer.contents().assumingMemoryBound(to: Float.self)
    for i in 0..<elementCount{
        print("Output element \(i) is \(outputs[i])")
    }
}
let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
commandEncoder.setComputePipelineState(computePipeline) // MTLComputePipelineState를 담는다.
commandEncoder.setBuffer(inputBufferA,offset: 0, index: 0)
commandEncoder.setBuffer(inputBufferB,offset: 0,index: 1)
commandEncoder.setBuffer(outputBuffer,offset: 0,index: 2)

commandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)
commandEncoder.endEncoding()
commandBuffer.commit()
