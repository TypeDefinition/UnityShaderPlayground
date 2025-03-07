// Header Guards
#ifndef MY_LIT_FORWARD_LIT_PASS_HLSL
#define MY_LIT_FORWARD_LIT_PASS_HLSL

// Pull in URP library functions and our own common functions.
// URP library functions can be found via the Unity Editor in "Packages/Universal RP/Shader Library/".
// The HLSL shader files for the URP are in the Packages/com.unity.render-pipelines.universal/ShaderLibrary/ folder in your project.
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "MyLitCommon.hlsl"

// This attributes struct receives data about the mesh we are currently rendering.
// Data is automatically placed in the fields according to their semantic.
// List of available semantics: https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
struct Attributes { // We can name this struct anything we want.
    float3 positionOS : POSITION; // Position in object space.
    float3 normalOS : NORMAL; // Normal in object space.
    float2 uv : TEXCOORD0; // Material texture UVs.
};

// A struct to define the variables we will pass from the vertex function to the fragment function.
struct Vert2Frag { // We can name this struct anything we want.
    // The output variable of the vertex shader must have the semantics SV_POSITION.
    // This value should contain the position in clip space when output from the vertex function.
    // It will be transformed into pixel position of the current fragment on the screen when read from the fragment function.
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0; // By the variable a TEXCOORDN semantic, Unity will automatically interpolate it for each fragment.
    float3 positionWS : TEXCOORD1; 
    float3 normalWS : TEXCOORD2; 
};

// The vertex function, runs once per vertex.
Vert2Frag Vertex(Attributes input) {
    // GetVertexPositionInputs is from ShaderVariableFunctions.hlsl in the URP package.
    // VertexPositionInputs is defined as
    /*
       struct VertexPositionInputs {
           float3 positionWS; // World space position
           float3 positionVS; // View space position
           float4 positionCS; // Homogeneous clip space position
           float4 positionNDC; // Homogeneous normalised device coordinates space position
       };
    */
    VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS); // Apply the model-view-projection transformations onto our position.
    VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS); // Apply the normal matrix transformation onto our normal.

    Vert2Frag output;
    output.positionCS = positionInputs.positionCS; // Set the clip space position.
    output.uv = TRANSFORM_TEX(input.uv, _AlbedoMap); // Get the UV position after applying offset & tiling.
    output.positionWS = positionInputs.positionWS; // Set the world space position.
    output.normalWS = normalInputs.normalWS;

    return output;
}

// The fragment function, runs once per pixel on the screen.
// It must have a float4 return type and have the SV_TARGET semantic.
// Values in the Vert2Frag have been interpolated based on each pixel's position.
float4 Fragment(Vert2Frag input
#ifdef _DOUBLE_SIDED_NORMALS
    ,FRONT_FACE_TYPE frontFace : FRONT_FACE_SEMANTIC // Optional parameter to determine if the surface is front facing or back facing.
#endif
) : SV_TARGET {
    // Sample the color map.
    float4 albedoSample = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv);
    
    TestAlphaClip(albedoSample * _Color);

    // Input Data holds information about the mesh at the current fragment.
    InputData inputData = (InputData)0; // Initialise it to 0.
    inputData.positionCS = input.positionCS;
    inputData.positionWS = input.positionWS;
    inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    inputData.normalWS = normalize(input.normalWS);

    // Set the shadow coordinates. Unity will automatically deal with the shadow mapping.
    // This is a float4. How does Unity know which light it's working on? Maybe this runs once per light?
    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);

    #ifdef _DOUBLE_SIDED_NORMALS
        inputData.normalWS *= IS_FRONT_VFACE(frontFace, 1, -1); // Flip the normal if it is back facing. (For transparent cutouts.)
    #endif

    // SurfaceData holds information about the material properties, such as colour.
    SurfaceData surfaceData = (SurfaceData)0; // Initialise it to 0.
    surfaceData.albedo = albedoSample.rgb * _Color.rgb;
    surfaceData.alpha = albedoSample.a * _Color.a;
    surfaceData.specular = _Specular;
    surfaceData.smoothness = _Smoothness;

    // UniversalFragmentBlinnPhong is a URP library helper function that does Blinn-Phong lighting for us.
    return UniversalFragmentBlinnPhong(inputData, surfaceData);
}

#endif // MY_LIT_FORWARD_LIT_PASS_HLSL