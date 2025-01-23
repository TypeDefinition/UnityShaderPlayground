Shader "Terri/MyLit" {
	// Properties are options set per material, exposed by the material inspector.
	// By convention, properties' names are declared _PropertyName("Label In Inspector", Type) = Value.
	// List of property types: https://docs.unity3d.com/Manual/SL-Properties.html
	Properties {
		[Header(Surface Options)] // Used to organise properties in the inspector.
		// [MainColor] & [MainTexture] allows Material.color and Material.mainTexture to use the correct properties.
		[MainColor] _Color("Color", Color) = (1, 1, 1, 1)
		[MainTexture] _AlbedoMap("Albedo", 2D) = "white" {}
		_Smoothness("Smoothness", Float) = 0
		_Specular("Specularity", Float) = 0.1
		_AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		// [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Integer) = 2 // Enum value of Back.

		[HideInInspector] _CullMode("Cull Mode", Integer) = 2 // Enum value of Back.
		[HideInInspector] _FaceRenderingMode("Face Rendering Mode", Integer) = 0

		[HideInInspector] _SurfaceType("Surface Type", Integer) = 0
		[HideInInspector] _SourceBlend("Source Blend", Integer) = 1 // Enum value of BlendMode.One.
		[HideInInspector] _DestBlend("Destination Blend", Integer) = 0 // Enum value of BlendMode.Zero.
		[HideInInspector] _ZWrite("ZWrite", Integer) = 1 // True
	}

	// Subshaders allow for different behaviour and options for different pipelines and platforms.
	SubShader {
		// These tags are shared by all passes in this sub shader.
		// List of sub shader tags: https://docs.unity3d.com/Manual/SL-SubShaderTags.html
		Tags { 
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Pass {
			Name "ForwardLit" // Name for debugging purposes.
			// List of pass tags: https://docs.unity3d.com/6000.0/Documentation/Manual/urp/urp-shaders/urp-shaderlab-pass-tags.html
			Tags{"LightMode" = "UniversalForward"} // UniversalForward tells unity that this pass is the forward lighting pass in URP.

			// Blend SrcAlpha OneMinusSrcAlpha
			// ZWrite Off
			Blend[_SourceBlend][_DestBlend]
			ZWrite [_ZWrite]
			Cull[_CullMode]

			HLSLPROGRAM // Begin HLSL code.

			// Enable specular lighting.
			#define _SPECULAR_COLOR

			// Tell the shader to find the function named "Vertex" in our HLSL code, and use it as the vertex function.
			#pragma vertex Vertex
			// Tell the shader to find the function named "Fragment" in our HLSL code, and use it as the fragment function.
			#pragma fragment Fragment

			// Unity 6 Forward+ renderer requires this on shaders for them to take realtime lights.
			#pragma multi_compile _ _FORWARD_PLUS
			
			// RECEIVE (not cast) shadows.
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile_fragment _ _SHADOWS_SOFT

			// Unlike multi compile macros, shader features always have an implicit _ as well.
			// Compile a version with _ALPHA_CUTOUT, and one without.
			#pragma shader_feature_local _ _ALPHA_CUTOUT
			#pragma shader_feature_local _ _DOUBLE_SIDED_NORMALS

			// Include our HLSL code. Seperating it out makes the code reusable.
			#include "HLSL/MyLitForwardLitPass.hlsl"

			ENDHLSL // End HLSL code.
		}

		// CAST (not receive) shadows.
		Pass {
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}

			Cull[_CullMode]

			// Tell the renderer that we don't need colour buffers.
			ColorMask 0

			HLSLPROGRAM

			#pragma vertex Vertex
			#pragma fragment Fragment

			#pragma shader_feature_local _ _ALPHA_CUTOUT
			#pragma shader_feature_local _ _DOUBLE_SIDED_NORMALS

			#include "HLSL/MyLitShadowCasterPass.hlsl"

			ENDHLSL
		}
	}

	CustomEditor "MyLitCustomInspector"
}