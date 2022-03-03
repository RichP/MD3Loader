//
//  Node.swift
//  multiplatform iOS
//
//  Created by Richard Pickup on 07/02/2022.
//

import Foundation

class Node {
    var name: String = "untitled"
    var position: float3 = [0, 0, 0]
    var rotation: float3 = [0, 0, 0]
    var scale: float3 = [1, 1, 1]
    
    var modelMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotationMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        
        return translateMatrix * rotationMatrix * scaleMatrix
    }
}
