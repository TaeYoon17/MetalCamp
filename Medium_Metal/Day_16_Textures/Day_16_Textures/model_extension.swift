//
//  model_extension.swift
//  Day_16_Textures
//
//  Created by 김태윤 on 2022/12/22.
//

import Foundation
import ModelIO

extension MDLVertexDescriptor{
    var vertexAttributes: [MDLVertexAttribute]{
        return attributes as! [MDLVertexAttribute]
    }
    var vertexLayouts: [MDLVertexBufferLayout]{
        return layouts as! [MDLVertexBufferLayout]
    }
}
