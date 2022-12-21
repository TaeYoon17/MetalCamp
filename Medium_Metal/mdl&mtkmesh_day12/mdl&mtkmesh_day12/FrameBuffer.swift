//
//  FrameBuffer.swift
//  mdl&mtkmesh_day12
//
//  Created by 김태윤 on 2022/11/25.
//

import Foundation
import MetalKit

struct FrameBuffer{
    private let maxCountIdx = 0
    var buffer: MTLBuffer!
    var nowIdx: Int = 0
    let strideSize: Int
    var nowOffset :Int {
        return strideSize * nowIdx
    }
    mutating func plusIdx(){
        nowIdx += 1
    }
}
