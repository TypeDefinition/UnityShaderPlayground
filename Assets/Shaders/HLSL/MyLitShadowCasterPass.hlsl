#ifndef MY_LIST_SHADOW_CASTER_PASS_HLSL
#define MY_LIST_SHADOW_CASTER_PASS_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "MyLitCommon.hlsl"

// _LightDirection (in World Space) is a uniform that Unity that automatically populate.
float3 _LightDirection;

struct Attributes {
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;

#ifdef _ALPHA_CUTOUT
    float2 uv : TEXCOORD0;
#endif
};

struct Vert2Frag {
    float4 positionCS : SV_POSITION;

#ifdef _ALPHA_CUTOUT
    float2 uv : TEXCOORD0;
#endif
};

float3 FlipNormalBasedOnViewDir(float3 normalWS, float3 positionWS) {
    float3 viewDirWS = GetWorldSpaceNormalizeViewDir(positionWS);
    return normalWS * (dot(normalWS, viewDirWS) < 0 ? -1 : 1);
}

float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS) {
    // Edit the shadow bias in the URP settings asset, or on each light using the editor.
    #ifdef _DOUBLE_SIDED_NORMALS
        normalWS = FlipNormalBasedOnViewDir(normalWS, positionWS);
    #endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
    
    // Some graphics API have the Z-axis reversed.
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
    #endif

    return positionCS;
}

Vert2Frag Vertex(Attributes input) {
    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS); // Apply the model-view-projection transformations onto our position.
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);

    // We need to add a bias to our shadow coordinates so that floating point errors will not cause shadow acne.
    Vert2Frag output;
    output.positionCS = GetShadowCasterPositionCS(positionInputs.positionWS, normalInputs.normalWS);

#ifdef _ALPHA_CUTOUT
    output.uv = TRANSFORM_TEX(input.uv, _AlbedoMap);
#endif

    return output;
}

float4 Fragment(Vert2Frag input) : SV_TARGET {
#ifdef _ALPHA_CUTOUT
    float4 albedoSample = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv);
    TestAlphaClip(albedoSample * _Color);
#endif

    // We only care about writing to the depth buffer and not the colour buffer, so we can just return 0.
    return 0;
}

#endif // MY_LIST_SHADOW_CASTER_PASS_HLSL