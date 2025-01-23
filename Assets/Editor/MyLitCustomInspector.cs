using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class MyLitCustomInspector : ShaderGUI {
    public enum SurfaceType {
        Opaque, Transparent
    }

    // Switch our shader between opaque and transparent based on the inspector.
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties) {
        Material material = materialEditor.target as Material;
        MaterialProperty surfaceProp = BaseShaderGUI.FindProperty("_SurfaceType", properties, true);

        EditorGUI.BeginChangeCheck();
        surfaceProp.intValue = (int)(SurfaceType)EditorGUILayout.EnumPopup("Surface Type", (SurfaceType)surfaceProp.intValue);
        if (EditorGUI.EndChangeCheck()) { UpdateSurfaceType(material); }

        base.OnGUI(materialEditor, properties);
    }

    // Update the surface type when the shader is first assigned to a material.
    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader) {
        base.AssignNewShaderToMaterial(material, oldShader, newShader);

        if (newShader.name == "Terri/MyLit") { UpdateSurfaceType(material); }
    }

    private void UpdateSurfaceType(Material material) {
        SurfaceType surfaceType = (SurfaceType)material.GetInteger("_SurfaceType");
        switch (surfaceType) {
            case SurfaceType.Opaque:
                material.renderQueue = (int)RenderQueue.Geometry;
                material.SetOverrideTag("RenderType", "Opaque");
                material.SetInteger("_SourceBlend", (int)BlendMode.One);
                material.SetInteger("_DestBlend", (int)BlendMode.Zero);
                material.SetInteger("_ZWrite", 1);
                material.SetShaderPassEnabled("ShadowCaster", true);
                break;
            case SurfaceType.Transparent:
                material.renderQueue = (int)RenderQueue.Transparent;
                material.SetOverrideTag("RenderType", "Transparent");
                material.SetInteger("_SourceBlend", (int)BlendMode.SrcAlpha);
                material.SetInteger("_DestBlend", (int)BlendMode.OneMinusSrcAlpha);
                material.SetInteger("_ZWrite", 0);
                material.SetShaderPassEnabled("ShadowCaster", false);
                break;
        }
    }
}