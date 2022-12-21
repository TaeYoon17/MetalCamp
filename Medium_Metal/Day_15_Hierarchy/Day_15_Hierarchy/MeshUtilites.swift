//
//  MeshUtilites.swift
//  Day_15_Hierarchy
//
//  Created by 김태윤 on 2022/12/21.
//

import ModelIO

extension MDLVertexDescriptor{
    var vertexAttributes: [MDLVertexAttribute]{
        return self.attributes as! [MDLVertexAttribute]
    }
    var vertexLayouts: [MDLVertexBufferLayout]{
        return self.layouts as! [MDLVertexBufferLayout]
    }
}
