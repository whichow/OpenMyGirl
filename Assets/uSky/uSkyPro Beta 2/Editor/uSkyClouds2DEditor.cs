using UnityEngine;
using UnityEditor;
using usky.Internal;

namespace usky
{
	[CustomEditor(typeof(uSkyClouds2D))]
	public class uSkyClouds2DEditor :  Editor 
	{
		uSkyClouds2D m_C2D;
		MaterialEditor m_MatEditor;
		SerializedObject serObj;
		SerializedProperty mat;
		SerializedProperty layer;

		private void OnEnable () 
		{
			serObj	= new SerializedObject (target);
			mat		= serObj.FindProperty ("Clouds2DMaterial");
			layer	= serObj.FindProperty ("cloudsLayer");
		}

		private void OnDisable()
		{
			if (m_MatEditor)
				DestroyImmediate (m_MatEditor);
		}

		public override void OnInspectorGUI (){  

			EditorGUI.BeginChangeCheck ();	

			serObj.Update ();
			EditorGUILayout.PropertyField (mat, new GUIContent ("Clouds 2D Material", "uSkyPro Clouds 2D material."));
			layer.intValue = EditorGUILayout.IntField(new GUIContent ("Clouds Layer", "Control which layer to render the clouds."), layer.intValue);
			serObj.ApplyModifiedProperties ();

			m_C2D = (uSkyClouds2D)target;
			Material m_Mat = m_C2D.Clouds2DMaterial;

			// no clouds material, do nothing
			if (m_Mat == null) {
				EditorGUILayout.HelpBox("Please apply a \"uSkyPro clouds 2D\" material", MessageType.Warning );
				OnDisable ();
				return;
			}
			else
			if (m_MatEditor == null) {
				m_MatEditor = (MaterialEditor) CreateEditor (m_Mat);
			} 

			// Note: Here detects only the material field and layer parameters dirtiness, not any of the material's parameters.
			// Detecting material's parameters dirtiness via "uSkyClouds2DShaderGUI" editor script.
			if (EditorGUI.EndChangeCheck ()) {
				// Material has changed? then create the new editor, and update the reflection probes.
				DestroyImmediate (m_MatEditor);
				m_MatEditor = (MaterialEditor) CreateEditor (m_Mat);
				uSkyInternal.MarkProbeStateDirty ();
			}

			// Draw material properties in inspector
			m_MatEditor.PropertiesGUI();	// read custom ShaderGUI, nice :)
		}
	}

}