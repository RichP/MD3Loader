//
//  Camera.swift
//  multiplatform
//
//  Created by Richard Pickup on 07/02/2022.
//

import Foundation
import simd

class Camera: Node {
    var fovDegrees: Float = 90
    var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 200
    
    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fovRadians,
                        near: near,
                        far: far,
                        aspect: aspect)
    }
    
    var viewMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotationMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        
        return (translateMatrix * rotationMatrix * scaleMatrix).inverse
    }
    
    func zoom(delta: Float) {}
    func rotate(delta: float2) {}
}

class ArcballCamera: Camera {
    var minDistance: Float = 0.5
    var maxDistance: Float = 10
    
    private var _viewMatrix = float4x4.identity()
    
    var target: float3 = [0, 0, 0] {
        didSet {
            _viewMatrix = updateViewMatrix()
        }
    }
    
    var distance: Float = 0 {
        didSet {
            _viewMatrix = updateViewMatrix()
        }
    }
    
    override var rotation: float3 {
        didSet {
            _viewMatrix = updateViewMatrix()
        }
    }
    
    override var viewMatrix: float4x4 {
        return _viewMatrix
    }
    
    override init() {
        super.init()
        _viewMatrix = updateViewMatrix()
    }
    
    private func updateViewMatrix() -> float4x4 {
        let translateMatix = float4x4(translation: [target.x, target.y, target.z - distance])
        let rotateMatrix = float4x4(rotationYXZ: [-rotation.x, rotation.y, 0])
        
        let matrix = (rotateMatrix * translateMatix).inverse
        position = rotateMatrix.upperLeft * -matrix.columns.3.xyz
        return matrix
    }
    
    override func zoom(delta: Float) {
        let sensitivity: Float = 0.05
        distance -= delta * sensitivity
        _viewMatrix = updateViewMatrix()
    }
    
    override func rotate(delta: float2) {
        let sensitivity: Float = 0.05
        rotation.x += delta.x * sensitivity
        rotation.y += delta.y * sensitivity
        rotation.x = max(-Float.pi / 2, min(rotation.x, Float.pi / 2))
        _viewMatrix = updateViewMatrix()
    }
}
