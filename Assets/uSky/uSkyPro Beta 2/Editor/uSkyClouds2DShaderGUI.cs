using UnityEngine;
using UnityEditor;
using usky.Internal;

public class uSkyClouds2DShaderGUI : ShaderGUI {

	override public void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
	{
//		GUILayout.Label("Clouds Params", EditorStyles.boldLabel);

		EditorGUI.BeginChangeCheck ();

		// render the shader properties using the default GUI
		base.OnGUI (materialEditor, properties);
//		materialEditor.PropertiesDefaultGUI(properties); // same as above line

		if (EditorGUI.EndChangeCheck ()) {
			uSkyInternal.MarkProbeStateDirty ();
		}
	}
}
