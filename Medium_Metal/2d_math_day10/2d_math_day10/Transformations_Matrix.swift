//
//  Transformations_Matrix.swift
//  2d_math_day10
//
//  Created by 김태윤 on 2022/11/14.
//
import MetalKit

extension simd_float4x4 {
    init(scale2D s: SIMD2<Float>) {
        self.init(SIMD4<Float>(s.x,   0, 0, 0),
                  SIMD4<Float>(  0, s.y, 0, 0),
                  SIMD4<Float>(  0,   0, 1, 0),
                  SIMD4<Float>(  0,   0, 0, 1))
    }
    init(rotateZ zRadians: Float) {
        let s = sin(zRadians)
        let c = cos(zRadians)
        self.init(SIMD4<Float>( c, s, 0, 0),
                  SIMD4<Float>(-s, c, 0, 0),
                  SIMD4<Float>( 0, 0, 1, 0),
                  SIMD4<Float>( 0, 0, 0, 1))
    }
    init(translate2D t: SIMD2<Float>) {
        self.init(SIMD4<Float>(  1,   0, 0, 0),
                  SIMD4<Float>(  0,   1, 0, 0),
                  SIMD4<Float>(  0,   0, 1, 0),
                  SIMD4<Float>(t.x, t.y, 0, 1))
    }
}
extension simd_float4x4 {
    init(orthographicProjectionWithLeft left: Float, top: Float,
         right: Float, bottom: Float, near: Float, far: Float)
    {
        let sx = 2 / (right - left)
        let sy = 2 / (top - bottom)
        let sz = 1 / (near - far)
        let tx = (left + right) / (left - right)
        let ty = (top + bottom) / (bottom - top)
        let tz = near / (near - far)
        self.init(SIMD4<Float>(sx,  0,  0, 0),
                  SIMD4<Float>( 0, sy,  0, 0),
                  SIMD4<Float>( 0,  0, sz, 0),
                  SIMD4<Float>(tx, ty, tz, 1))
    }
    static func getIdentity()->simd_float4x4{
        var temp = simd_float4x4()
        temp.columns.0[0] = 1
        temp.columns.1[1] = 1
        temp.columns.2[2] = 1
        temp.columns.3[3] = 1
        return temp
    }
}
