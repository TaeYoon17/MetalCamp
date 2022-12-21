//
//  Node.swift
//  Day_15_Hierarchy
//
//  Created by 김태윤 on 2022/12/21.
//

import simd
import MetalKit
class Node{
    var mesh: MTKMesh?
    var color = SIMD4<Float>(1,1,1,1)
    
    var transform: simd_float4x4 = matrix_identity_float4x4
    
    // 재귀적 호출을 한다.
    var worldTransform: simd_float4x4{
        if let parent = parentNode{
            return parent.worldTransform * transform
        }else{
            return transform
        }
    }
    var parentNode: Node?
    
    private(set) var childNodes = [Node]()
    init(){}
    init(mesh: MTKMesh){
        self.mesh = mesh
    }
    func addChildNode(_ node:Node){
        childNodes.append(node)
        node.parentNode = self
    }
    func removeFromParent(){
        parentNode?.removeChildNode(self)
    }
    private func removeChildNode(_ node:Node){
        childNodes.removeAll{$0 === node}
    }
}
