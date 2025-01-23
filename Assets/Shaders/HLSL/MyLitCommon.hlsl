// Header Guards
#ifndef MY_LIT_COMMON_HLSL
#define MY_LIT_COMMON_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// Material Properties
// Textures are a little more complicated to deal with.
TEXTURE2D(_AlbedoMap); // TEXTURE2D is actually a macro, not a type. This is because behind the scenes, HLSL will replace this with whatever texture type the graphics API you're using. (OpenGL, DirectX, Metal, Vulkan, etc.)
SAMPLER(sampler_AlbedoMap); // The sampler MUST be named "sampler_" + "texture name".
float4 _AlbedoMap_ST; // This contains the UV tiling and offset data, and is automatically set by Unity. It MUST be named "texture name" + "_ST". Used in TRANSFORM_TEX to apply UV tiling.

// Even though we declared this in the ShaderLab file, we also need to redeclare it in the HLSL file, and make sure the name exactly matches.
float4 _Color;
float _Smoothness;
float _Specular;
float _AlphaCutoff;

// Discard any fragments with alpha less than or equal to _AlphaCutoff.
void TestAlphaClip(float4 colorSample) {
#ifdef _ALPHA_CUTOUT
    clip(colorSample.a - _AlphaCutoff);
#endif
}

#endif // MY_LIT_COMMON_HLSL