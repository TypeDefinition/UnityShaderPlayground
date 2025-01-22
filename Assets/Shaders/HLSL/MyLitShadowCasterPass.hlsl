#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// _LightDirection (in World Space) is a uniform that Unity that automatically populate.
float3 _LightDirection;

struct Attributes {
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
};

struct Vert2Frag {
    float4 positionCS : SV_POSITION;
};

float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS) {
    // Edit the shadow bias in the URP settings asset, or on each light using the editor.
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
    return output;
}

float4 Fragment(Vert2Frag input) : SV_TARGET {
    // We only care about writing to the depth buffer and not the colour buffer, so we can just return 0.
    return 0;
}