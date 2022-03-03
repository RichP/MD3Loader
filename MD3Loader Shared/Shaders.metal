//
//  Shaders.metal
//  multiplatform Shared
//
//  Created by Richard Pickup on 02/02/2022.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
using namespace metal;
#include "Common.h"

struct VertexIn {
//    packed_float3 position;
//    packed_float3 normal;
    
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float3 uv [[attribute(UV)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
};

//vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
//                          constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]]) {
//
//    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * vertexIn.position;
//
//    VertexOut vertex_out {
//        .position = position,
//        // 4
//        .point_size = 10.0
//      };
//
//
//  //float4 position = vertexIn.position;
// // position.y += timer;
//  return vertex_out;
//}

vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                            // uint vertexID [[vertex_id]],
                             constant Uniforms &uniforms [[buffer(BufferIndexUniforms)]]) {
    //VertexIn vertexIn = in[vertexID];
    //float4 posIn = float4(vertexIn.position, 1);
    float4 posIn = vertexIn.position;
    float3 normIn = vertexIn.normal;
    float3 uvIn = vertexIn.uv;
    
    float4 position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * posIn;
    
    VertexOut vertex_out {
        .position = position,
        .worldPosition = (uniforms.modelMatrix * posIn).xyz,
        .worldNormal = uniforms.normalMatrix * normIn,
        .uv = uvIn.xy
      };
    
    
  //float4 position = vertexIn.position;
 // position.y += timer;
  return vertex_out;
}
//
//fragment float4 fragment_main(VertexOut in [[stage_in]],
//                              // 1
//                              constant Light *lights [[buffer(2)]],
//                              constant FragmentUniforms &fragmentUniforms [[ buffer(3)]]) {
//  float3 baseColor = float3(1, 1, 1);
//  float3 diffuseColor = 0;
//  float3 ambientColor = 0;
//  float3 specularColor = 0;
//  float materialShininess = 32;
//  float3 materialSpecularColor = float3(1, 1, 1);
//  // 2
//  float3 normalDirection = normalize(in.worldNormal);
//  for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
//    Light light = lights[i];
//    if (light.type == SunLight) {
//      float3 lightDirection = normalize(light.position);
//      // 3
//      float diffuseIntensity =
//      saturate(dot(lightDirection, normalDirection));
//      // 4
//      diffuseColor += light.color * baseColor * diffuseIntensity;
//      if (diffuseIntensity > 0) {
//        // 1 (R)
//        float3 reflection =
//        reflect(lightDirection, normalDirection);
//        // 2 (V)
//        float3 cameraPosition =
//        normalize(in.worldPosition - fragmentUniforms.cameraPosition);
//        // 3
//        float specularIntensity =
//        pow(saturate(dot(reflection, cameraPosition)), materialShininess);
//        specularColor +=
//        light.specularColor * materialSpecularColor * specularIntensity;
//      }
//    } else if (light.type == AmbientLight) {
//      ambientColor += light.color * light.intensity;
//    } else if (light.type == PointLight) {
//      // 1
//      float d = distance(light.position, in.worldPosition);
//      // 2
//      float3 lightDirection = normalize(light.position - in.worldPosition);
//      // 3
//      float attenuation = 1.0 / (light.attenuation.x +
//                                 light.attenuation.y * d + light.attenuation.z * d * d);
//
//      float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
//      float3 color = light.color * baseColor * diffuseIntensity;
//      // 4
//      color *= attenuation;
//      diffuseColor += color;
//    } else if (light.type == SpotLight) {
//      // 1
//      float d = distance(light.position, in.worldPosition);
//      float3 lightDirection = normalize(light.position - in.worldPosition);
//      // 2
//      float3 coneDirection = normalize(-light.coneDirection);
//      float spotResult = (dot(lightDirection, coneDirection));
//      // 3
//      if (spotResult > cos(light.coneAngle)) {
//        float attenuation = 1.0 / (light.attenuation.x +
//                                   light.attenuation.y * d + light.attenuation.z * d * d);
//        // 4
//        attenuation *= pow(spotResult, light.coneAttenuation);
//        float diffuseIntensity = saturate(dot(lightDirection, normalDirection));
//        float3 color = light.color * baseColor * diffuseIntensity;
//        color *= attenuation;
//        diffuseColor += color;
//      }
//    }
//  }
//  // 5
//  float3 color = diffuseColor + ambientColor + specularColor;
//  return float4(color, 1);
//}



fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> baseColorTexture [[texture(BaseColorTexture)]],
                              sampler textureSampler [[sampler(0)]],
                              constant Light *lights [[buffer(BufferIndexLights)]],
                              constant FragmentUniforms &fragmentUniforms [[buffer(BufferIndexFragmentUniforms)]]) {
    
    //float3 baseColor = float3(1, 1, 1);
    
    float3 baseColor = baseColorTexture.sample(textureSampler,
                                        in.uv).rgb;
    
    //return float4(baseColor, 1);
    
    
     float3 diffuseColor = 0;
     float3 ambientColor = 0;
     float3 specularColor = 0;
     float materialShininess = 32;
     float3 materialSpecularColor = float3(1, 1, 1);
     // 2
     float3 normalDirection = normalize(in.worldNormal);
    
    for (uint i = 0; i < fragmentUniforms.lightCount; i++) {
        Light light = lights[i];
        
        if (light.type == SunLight) {
            float3 lightDirection = normalize(-light.position);
            
            float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
            
            if (diffuseIntensity > 0) {
                float3 reflection = reflect(lightDirection, normalDirection);
                
                float3 cameraDirection = normalize(in.worldPosition - fragmentUniforms.cameraPosition);
                
                float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShininess);
                
                specularColor += light.specularColor * materialSpecularColor * specularIntensity;
            }
            
            diffuseColor += light.color * baseColor * diffuseIntensity;
        } else if (light.type == AmbientLight) {
            ambientColor += light.color * light.intensity;
        } else if (light.type == PointLight) {
            float d = distance(light.position, in.worldPosition);
            
            float3 lightDirection = normalize(in.worldPosition - light.position);
            
            float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
            
            float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
            
            float3 color = light.color * baseColor * diffuseIntensity;
            
            color *= attenuation;
            
            diffuseColor += color;
        } else if (light.type == SpotLight) {
            float d = distance(light.position, in.worldPosition);
            float3 lightDirection = normalize(in.worldPosition - light.position);
            float3 coneDirection = normalize(light.coneDirection);
            float spotResult = dot(lightDirection, coneDirection);
            
            if ( spotResult > cos(light.coneAngle)) {
                float attenuation = 1.0 / (light.attenuation.x + light.attenuation.y * d + light.attenuation.z * d * d);
                
                attenuation *= pow(spotResult, light.coneAttenuation);
                
                float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
                
                float3 color = light.color * baseColor * diffuseIntensity;
                color *= attenuation;
                diffuseColor += color;
            }
        }
    }
    
    
    float3 color = diffuseColor + ambientColor + specularColor;
      return float4(color, 1);
}
