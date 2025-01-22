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

		[HideInInspector] _SourceBlend("Source Blend", Float) = 0
		[HideInInspector] _DestBlend("Destination Blend", Float) = 0
		[HideInInspector] _ZWrite("ZWrite", Float) = 0

		[HideInInspector] _SurfaceType("Surface Type", Float) = 0
	}

	// Subshaders allow for different behaviour and options for different pipelines and platforms.
	SubShader {
		// These tags are shared by all passes in this sub shader.
		// List of sub shader tags: https://docs.unity3d.com/Manual/SL-SubShaderTags.html
		Tags {
			"RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"

			// "RenderType" = "Transparent"
			// "Queue" = "Transparent"
		}

		Pass {
			Name "ForwardLit" // Name for debugging purposes.
			// List of pass tags: https://docs.unity3d.com/6000.0/Documentation/Manual/urp/urp-shaders/urp-shaderlab-pass-tags.html
			Tags{"LightMode" = "UniversalForward"} // UniversalForward tells unity that this pass is the forward lighting pass in URP.

			// Blend SrcAlpha OneMinusSrcAlpha
			Blend[_SourceBlend][_DestBlend]
			ZWrite [_ZWrite]

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

			// Include our HLSL code. Seperating it out makes the code reusable.
			#include "HLSL/MyLitForwardLitPass.hlsl"

			ENDHLSL // End HLSL code.
		}

		// CAST (not receive) shadows.
		Pass {
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}

			// Tell the renderer that we don't need colour buffers.
			ColorMask 0

			HLSLPROGRAM
			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "HLSL/MyLitShadowCasterPass.hlsl"
			ENDHLSL
		}
	}

	CustomEditor "MyLitCustomInspector"
}