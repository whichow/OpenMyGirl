using UnityEngine;
using UnityEditor;

namespace usky
{
	[CanEditMultipleObjects, CustomEditor(typeof(uSkyReflectionProbeUpdater))]
	public class uSkyReflectionProbeUpdaterEditor : Editor 
	{
		SerializedObject	serObj;
		SerializedProperty	timeSlicing;
		
		private void OnEnable () 
		{
			serObj		= new SerializedObject (target);
			timeSlicing	= serObj.FindProperty ("RuntimeTimeSlicing");
		}

		public override void OnInspectorGUI()
		{
			serObj.Update ();
			EditorGUILayout.PropertyField (timeSlicing);
			serObj.ApplyModifiedProperties();
		}
	}
}
