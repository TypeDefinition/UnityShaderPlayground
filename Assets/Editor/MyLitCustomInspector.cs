using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class MyLitCustomInspector : ShaderGUI {
    public enum SurfaceType {
        Opaque, TransparentCutout, TransparentBlend
    }

    public enum FaceRenderingMode {
        FrontOnly, NoCulling, DoubleSided
    }

    // Switch our shader between opaque and transparent based on the inspector.
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        Material material = materialEditor.target as Material;
        MaterialProperty surfaceProp = BaseShaderGUI.FindProperty("_SurfaceType", properties, true);
        MaterialProperty faceProp = BaseShaderGUI.FindProperty("_FaceRenderingMode", properties, true);

        EditorGUI.BeginChangeCheck();
        surfaceProp.intValue = (int)(SurfaceType)EditorGUILayout.EnumPopup("Surface Type", (SurfaceType)surfaceProp.intValue);
        faceProp.intValue = (int)(FaceRenderingMode)EditorGUILayout.EnumPopup("Face Rendering Mode", (FaceRenderingMode)surfaceProp.intValue);
        if (EditorGUI.EndChangeCheck()) { UpdateMaterial(material); }

        base.OnGUI(materialEditor, properties);
    }

    // Update the surface type when the shader is first assigned to a material.
    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader) {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);

        if (newShader.name == "Terri/MyLit") { UpdateMaterial(material); }
    }

    private void UpdateMaterial(Material material) {
        SurfaceType surfaceType = (SurfaceType)material.GetInteger("_SurfaceType");
        switch (surfaceType) {
            case SurfaceType.Opaque:
                material.renderQueue = (int)RenderQueue.Geometry;
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetInteger("_SourceBlend", (int)BlendMode.One);
                material.SetInteger("_DestBlend", (int)BlendMode.Zero);
                material.SetInteger("_ZWrite", 1);
                material.SetShaderPassEnabled("ShadowCaster", true);
                material.DisableKeyword("_ALPHA_CUTOUT"); // Undefine macro.
                break;
            case SurfaceType.TransparentCutout:
                material.renderQueue = (int)RenderQueue.AlphaTest;
                material.SetOverrideTag("RenderType", "TransparentCutout");
                material.SetInteger("_SourceBlend", (int)BlendMode.One);
                material.SetInteger("_DestBlend", (int)BlendMode.Zero);
                material.SetInteger("_ZWrite", 1);
                material.SetShaderPassEnabled("ShadowCaster", true);
                material.EnableKeyword("_ALPHA_CUTOUT"); // Define macro.
                break;
            case SurfaceType.TransparentBlend:
                material.renderQueue = (int)RenderQueue.Transparent;
                material.SetOverrideTag("RenderType", "TransparentBlend");
                material.SetInteger("_SourceBlend", (int)BlendMode.SrcAlpha);
                material.SetInteger("_DestBlend", (int)BlendMode.OneMinusSrcAlpha);
                material.SetInteger("_ZWrite", 0);
                material.SetShaderPassEnabled("ShadowCaster", false);
                material.DisableKeyword("_ALPHA_CUTOUT"); // Undefine macro.
                break;
        }

        FaceRenderingMode faceRenderingMode = (FaceRenderingMode)material.GetInteger("_FaceRenderingMode");
        switch (faceRenderingMode) {
            case FaceRenderingMode.FrontOnly:
                material.SetInteger("_CullMode", (int)UnityEngine.Rendering.CullMode.Back);
                material.DisableKeyword("_DOUBLE_SIDED_NORMALS");
                break;
            case FaceRenderingMode.NoCulling:
                material.SetInteger("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
                material.DisableKeyword("_DOUBLE_SIDED_NORMALS");
                break;
            case FaceRenderingMode.DoubleSided:
                material.SetInteger("_CullMode", (int)UnityEngine.Rendering.CullMode.Off);
                material.EnableKeyword("_DOUBLE_SIDED_NORMALS");
                break;
        }
    }
}