//
//  Common.h
//  multiplatform
//
//  Created by Richard Pickup on 05/02/2022.
//

#ifndef Common_h
#define Common_h
#import <simd/simd.h>

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 11,
    BufferIndexLights = 12,
    BufferIndexFragmentUniforms = 13,
    BufferIndexMaterials = 14
} BufferIndices;

typedef enum {
    Position = 0,
    Normal = 1,
    UV = 2,
    Tangent = 3,
    Bitangent = 4
} Attributes;

typedef enum {
    BaseColorTexture = 0,
    NormalTexture = 1
} Textures;

typedef struct {
    vector_float3 baseColor;
    vector_float3 specularColor;
    float roughness;
    float metalic;
    vector_float3 ambientOcclusion;
    float shininess;
} Material;

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    
    matrix_float3x3 normalMatrix;
    
} Uniforms;

typedef enum {
    unused = 0,
    SunLight = 1,
    SpotLight = 2,
    PointLight = 3,
    AmbientLight = 4
} LightType;

typedef struct {
    float coneAngle;
    vector_float3 coneDirection;
    float coneAttenuation;
    
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    LightType type;
} Light;

typedef struct {
    uint lightCount;
    vector_float3 cameraPosition;
    uint tiling;
} FragmentUniforms;

#endif /* Common_h */
