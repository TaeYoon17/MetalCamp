import Cocoa
import Metal

let device = MTLCreateSystemDefaultDevice()!

print("Device name: \(device.name)")

// 디바이스 메모리에 16byte 할당
let buffer = device.makeBuffer(length: 16,options: [])!
print("Buffer is \(buffer.length) bytes in length")
// Float은 4바이트, SIMD2는 2차원 배열 => 총 8바이트 / capacity는 2개
// points: [(float,float),(float,float)]
let points = buffer.contents().bindMemory(to: SIMD2<Float>.self, capacity: 2)

points[0] = SIMD2<Float>(10,10)
points[1] = SIMD2<Float>(100,100)

print(points[0])

/// 명령이 필요한 이유
/// Metal은 데이터를 만들고 모양을 그리는 작업을 동시에 못한다.
/// 그래서 미리 그리는 작업을 담아놓고 모양을 만들고 나서 담아놓은 그리는 작업을 자동으로 실행한다.

// GPU로 보내질 명령의 대기열
let commandQueue = device.makeCommandQueue()!
// GPU로 보내질 명령의 버퍼들
let commandBufer = commandQueue.makeCommandBuffer()!
commandBufer.addCompletedHandler { completedCommandBuffer in
    print("명령버퍼 처리 완료")
}
commandBufer.commit()
// MTLBlitCommandEncoder: 메모리 복사, 필터링 및 채우기 명령을 인코딩하는 인코더.
