//
//  Node.swift
//  Day_16_Textures
//
//  Created by 김태윤 on 2022/12/22.
//

import MetalKit
import simd
class Node{
    var mesh: MTKMesh?
    var texture: MTLTexture?
    var transform: simd_float4x4 = matrix_identity_float4x4
    var worldTransform: simd_float4x4{
        if let parent = self.parentNode{
            return parent.worldTransform * transform
        }else {
            return transform
        }
    }
    weak var parentNode: Node?
    
    private(set) var childNodes = [Node]()
    
    init(){}
    
    init(mesh: MTKMesh){
        self.mesh = mesh
    }
    func addChildNode(_ node: Node){
        childNodes.append(node)
        node.parentNode = self
    }
    func removeFromParent(){
        self.parentNode?.removeChildNode(self)
    }
    private func removeChildNode(_ node:Node){
        childNodes.removeAll{ $0 === node}
    }
}
