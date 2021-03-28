using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
	using UnityEditor;
#endif

#if UNITY_EDITOR
public class AnimatedShaderGUI : ShaderGUI
{
	private static class Styles
	{
		// sections
		public static GUIContent MainSection = new GUIContent("Main Settings");
		public static GUIContent EmissionSection = new GUIContent("Emission Settings");
		public static GUIContent MiscSection = new GUIContent("Miscellaneous Settings");
		
		// main section
		public static GUIContent MainTex = new GUIContent("Animation", "Sprite Sheet");
		public static GUIContent Color = new GUIContent("Color", "Tint Animation Color");
		public static GUIContent Cutoff = new GUIContent("Cutoff", "Alpha Transparency Cutoff");
		public static GUIContent Speed = new GUIContent("Speed", "Frames Per Second");
		
		// emission section
		public static GUIContent Emission = new GUIContent("Enable Emission", "Enables Emission");
		public static GUIContent AutoEmission = new GUIContent("Dynamic Emission", "Make a chosen color emissive rather than referring to an emission map");
		public static GUIContent AutoEmisColor = new GUIContent("Emissive Color", "Color Made emissive");
		public static GUIContent AutoEmisThres = new GUIContent("Similarity Threshold", "Range of Similarity to the Color");
		public static GUIContent EmissionMap = new GUIContent("Emission Map", "Emission Map for the Animation");
		public static GUIContent EmissionColor = new GUIContent("Emission Color", "Tint Emission Color");
		public static GUIContent EmissionStrength = new GUIContent("Emission Strength", "Strength of the Emission");
		
		// misc section
		public static GUIContent DoubleSidedIllum = new GUIContent("Double Sided Illumination", "Illuminate Both Sides of Mesh Faces");
		public static GUIContent Culling = new GUIContent("Cull Mode", "Which Side of Faces Not to Render");
	}

	GUIStyle m_sectionStyle;

	MaterialProperty m_mainTex = null;
	MaterialProperty m_color = null;
	MaterialProperty m_cutoff = null;
	MaterialProperty m_speed = null;

	MaterialProperty m_emission = null;
	MaterialProperty m_autoEmission = null;
	MaterialProperty m_autoEmisColor = null;
	MaterialProperty m_autoEmisThres = null;
	MaterialProperty m_emissionMap = null;
	MaterialProperty m_emissionColor = null;
	MaterialProperty m_emissionStrength = null;

	MaterialProperty m_doubleSidedIllum = null;
	MaterialProperty m_culling = null;

	bool m_mainSection;
	bool m_emissionSection;
	bool m_miscSection;

	private void FindProperties(MaterialProperty[] props)
	{
		m_mainTex = FindProperty("_MainTex", props);
		m_color = FindProperty("_Color", props);
		m_cutoff = FindProperty("_Cutoff", props);
		m_speed = FindProperty("_Speed", props);
		
		m_emission = FindProperty("_EMISSION", props);
		m_autoEmission = FindProperty("_AUTOMATIC", props);
		m_autoEmisColor = FindProperty("_AutoEmisColor", props);
		m_autoEmisThres = FindProperty("_AutoEmisThres", props);
		m_emissionMap = FindProperty("_EmissionMap", props);
		m_emissionColor = FindProperty("_EmissionColor", props);
		m_emissionStrength = FindProperty("_EmissionStrength", props);
		
		m_doubleSidedIllum = FindProperty("_DOUBLE_SIDED_ILLUM", props);
		m_culling = FindProperty("_Cull", props);
	}

	private void SetupStyle()
	{
		m_sectionStyle = new GUIStyle(EditorStyles.boldLabel);
		m_sectionStyle.alignment = TextAnchor.LowerLeft;
		m_sectionStyle.fontSize = 12;
	}

	private void ToggleDefine(Material mat, string define, bool state)
	{
		if (state)
		{
			mat.EnableKeyword(define);
		}
		else
		{
			mat.DisableKeyword(define);
		}
	}
	void ToggleDefines(Material mat)
	{
	}

	void LoadDefaults(Material mat)
	{
	}

	void DrawHeader(ref bool enabled, ref bool options, GUIContent name)
	{
		var r = EditorGUILayout.BeginHorizontal("box");
		enabled = EditorGUILayout.Toggle(enabled, EditorStyles.radioButton, GUILayout.MaxWidth(15.0f));
		options = GUI.Toggle(r, options, GUIContent.none, new GUIStyle());
		EditorGUILayout.LabelField(name, m_sectionStyle);
		EditorGUILayout.EndHorizontal();
	}

	void DrawMasterLabel()
	{
		GUIStyle style = new GUIStyle(GUI.skin.label);
		style.richText = true;
		style.alignment = TextAnchor.MiddleCenter;

		EditorGUILayout.LabelField("<size=18><color=#940000>Joshua's Animated Shader</color></size>", style, GUILayout.MaxHeight(50));
	}

	public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
	{
		Material material = materialEditor.target as Material;

		// map shader properties to script variables
		FindProperties(props);

		// set up style for the base look
		SetupStyle();

		// load default toggle values
		LoadDefaults(material);

		DrawMasterLabel();

		// main section
		m_mainSection = GUI.Toggle(EditorGUILayout.BeginHorizontal("box"), m_mainSection, GUIContent.none, "box");
		EditorGUILayout.LabelField(Styles.MainSection, m_sectionStyle);
		EditorGUILayout.EndHorizontal();	

		EditorGUI.indentLevel++;	  
		materialEditor.ShaderProperty(m_mainTex, Styles.MainTex);
		materialEditor.ShaderProperty(m_color, Styles.Color);
		materialEditor.ShaderProperty(m_cutoff, Styles.Cutoff);
		materialEditor.ShaderProperty(m_speed, Styles.Speed);
		EditorGUI.indentLevel--;	  
		EditorGUILayout.Space();

		// emission section
		m_emissionSection = GUI.Toggle(EditorGUILayout.BeginHorizontal("box"), m_emissionSection, GUIContent.none, "box");
		EditorGUILayout.LabelField(Styles.EmissionSection, m_sectionStyle);
		EditorGUILayout.EndHorizontal();

		EditorGUI.indentLevel++;
		materialEditor.ShaderProperty(m_emission, Styles.Emission);
		if (m_emission.floatValue == 1)
		{
			materialEditor.ShaderProperty(m_autoEmission, Styles.AutoEmission);
			if (m_autoEmission.floatValue == 1)
			{
				materialEditor.ShaderProperty(m_autoEmisColor, Styles.AutoEmisColor);
				materialEditor.ShaderProperty(m_autoEmisThres, Styles.AutoEmisThres);
			}
			else
			{
				materialEditor.ShaderProperty(m_emissionMap, Styles.EmissionMap);
				materialEditor.ShaderProperty(m_emissionColor, Styles.EmissionColor);
			}
			materialEditor.ShaderProperty(m_emissionStrength, Styles.EmissionStrength);
		}
		EditorGUI.indentLevel--;
		EditorGUILayout.Space();
		
		// misc settings
		m_miscSection = GUI.Toggle(EditorGUILayout.BeginHorizontal("box"), m_miscSection, GUIContent.none, "box");
		EditorGUILayout.LabelField(Styles.MiscSection, m_sectionStyle);
		EditorGUILayout.EndHorizontal();
		
		EditorGUI.indentLevel++;
		materialEditor.ShaderProperty(m_doubleSidedIllum, Styles.DoubleSidedIllum);
		materialEditor.ShaderProperty(m_culling, Styles.Culling);
		EditorGUI.indentLevel--;
		EditorGUILayout.Space();

		ToggleDefines(material);
	}
}
#endif
