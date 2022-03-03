//
//  Lighting.swift
//  multiplatform
//
//  Created by Richard Pickup on 08/02/2022.
//

import Foundation

struct Lighting {
    
     var sunlight: Light = {
         var light = Lighting.buildDefaultLight()
        light.position = [-0.4, -20.5, 2]
         light.specularColor = [0, 0, 0]
         light.color = [1, 1, 1]
        return light
    }()
    
     var ambientLight: Light = {
         var light = Lighting.buildDefaultLight()
        light.color = [1, 1, 1]
        light.intensity = 0.2
        light.type = AmbientLight
        return light
    }()
    
     var fillLight: Light = {
         var light = Lighting.buildDefaultLight()
        light.position = [0, 20, 0.4]
        light.specularColor = [0, 0, 0]
        light.color = [0.4, 0.4, 0.0]
        return light
    }()
    
    var redLight: Light = {
        var light = Lighting.buildDefaultLight()
        light.position = [0, 7, 0]
        light.color = [1, 0, 0]
        light.attenuation = float3(0.5, 1.5, 2.5)
        light.type = PointLight
        return light
    }()
    
    var spotlight: Light = {
        var light = Lighting.buildDefaultLight()
        light.position = [0, -20, 0]
        light.color = [1, 0, 1]
        light.attenuation = float3(1, 0.5, 0)
        light.type = SpotLight
        light.coneAngle = Float(20).degreesToRadians
        light.coneDirection = [0, 10, 0]
        light.coneAttenuation = 1
        return light
    }()
    
    let lights: [Light]
    let count: UInt32
    
    init() {
        lights = [sunlight, fillLight, ambientLight, redLight, spotlight]
        count = UInt32(lights.count)
    }
    
    
    static func buildDefaultLight() -> Light {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [1, 1, 1]
        light.intensity = 0.6
        light.attenuation = float3(1, 0, 0)
        light.type = SunLight
        return light
    }
}
