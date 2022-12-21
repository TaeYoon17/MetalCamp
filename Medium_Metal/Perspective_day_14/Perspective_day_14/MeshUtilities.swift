//
//  MeshUtilities.swift
//  Perspective_day_14
//
//  Created by 김태윤 on 2022/12/21.
//

import MetalKit
import ModelIO

extension MDLVertexDescriptor{
    var vertexAttributes: [MDLVertexAttribute]{
        return self.attributes as! [MDLVertexAttribute]
    }
    var bufferLayouts: [MDLVertexBufferLayout]{
        return layouts as! [MDLVertexBufferLayout]
    }
}
