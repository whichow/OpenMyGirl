using UnityEngine;
using UnityEditor;

namespace usky
{
	[CustomEditor(typeof(uSkyTimeline))]
	public class uSkyTimelineEditor : Editor 
	{
		SerializedObject	serObj;
		SerializedProperty	type;
		SerializedProperty	timeline;
		SerializedProperty	defaultMode;
		SerializedProperty	realisticMode;
		SerializedProperty	dayNightCycle;
		SerializedProperty	accumulatedTime;
		SerializedProperty	actualTime;


		private void OnEnable () 
		{
			serObj			= new SerializedObject (target);
			type			= serObj.FindProperty ("type");
			timeline		= serObj.FindProperty ("timeline");
			defaultMode		= serObj.FindProperty ("sunAndMoon");
			realisticMode	= serObj.FindProperty ("locationAndDate");
			dayNightCycle	= serObj.FindProperty ("dayNightCycle");
			accumulatedTime	= serObj.FindProperty ("m_AccumulatedTime");
			actualTime		= serObj.FindProperty ("m_ActualTime");

		}

		public override void OnInspectorGUI()
		{

			serObj.Update();

//			EditorGUILayout.Space();

			EditorGUILayout.PropertyField (type);
			EditorGUILayout.PropertyField (timeline);

			EditorGUILayout.Space ();

			if (type.enumValueIndex == 0)
			{
				EditorGUILayout.PropertyField (defaultMode, true) ;
			} 
			else
			{
				EditorGUILayout.PropertyField (realisticMode, true);
			}

			EditorGUILayout.PropertyField (dayNightCycle);

			if (dayNightCycle.isExpanded) 
			{
				Rect rect1 = EditorGUILayout.GetControlRect ();
				rect1.y -= 10;
				Rect rect2 = rect1;
				rect1.x += EditorGUIUtility.labelWidth;
				rect1.width -= EditorGUIUtility.labelWidth;

				float ProgressInterval = accumulatedTime.floatValue / Mathf.Max( Mathf.Epsilon, dayNightCycle.FindPropertyRelative("steppedInterval").floatValue);
				EditorGUI.ProgressBar (rect1, ProgressInterval , "");

				GUI.enabled = false; // same as using EditorGUI.BeginDisabledGroup ()
				EditorGUI.FloatField (rect2, "Actual Time Counter", actualTime.floatValue);
			}

			serObj.ApplyModifiedProperties();
		}

	}
}