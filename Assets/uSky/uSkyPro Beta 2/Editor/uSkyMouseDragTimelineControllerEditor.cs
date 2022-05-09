using UnityEngine;
using UnityEditor;

namespace usky
{
	[CustomEditor(typeof(MouseDragTimelineController))]
	public class MouseDragTimelineControllerEditor : Editor 
	{
		SerializedObject	serObj;
//		SerializedProperty	controlButton;
		SerializedProperty	moveSpeed;

		uSkyTimeline uST { get { return uSkyTimeline.instance; } }

		private void OnEnable () 
		{
			serObj			= new SerializedObject (target);
//			controlButton	= serObj.FindProperty ("ControlButton");
			moveSpeed		= serObj.FindProperty ("MoveSpeed");
		}

		public override void OnInspectorGUI()
		{
			serObj.Update ();
			EditorGUILayout.Space();
//			EditorGUILayout.PropertyField (controlButton, new GUIContent ("Control Button", "Main mouse button to drag on screen"));
			EditorGUILayout.PropertyField (moveSpeed);
			serObj.ApplyModifiedProperties();

			if (uST == null)
				EditorGUILayout.HelpBox("This controller requires uSkyTimeline to work", MessageType.Warning );
			else
			if (uST.Type == TimeSettingsMode.Realistic)
				EditorGUILayout.HelpBox("This controller works better with \"Default\" type in uSkyTimeline", MessageType.Info );
		}
	}
}
