//
//  MeshExtension.swift
//  Depth_Day_13
//
//  Created by 김태윤 on 2022/12/14.
//

import MetalKit
import ModelIO

extension MDLVertexDescriptor{
    var vertexAttributes: [MDLVertexAttribute]{
        return attributes as! [MDLVertexAttribute]
    }
    var bufferLayouts: [MDLVertexBufferLayout]{
        return layouts as! [MDLVertexBufferLayout]
    }
}
