using UnityEngine;
using UnityEditor;

namespace usky
{
	public class uSkyTimelineWindow : EditorWindow
	{
		private static uSkyTimelineWindow window;

		SerializedObject	serObj;
		SerializedProperty	timeline;

		uSkyTimeline uST { get{ return uSkyTimeline.instance; }}

		[MenuItem ("Window/uSky Timeline window")]
		static void Init ()
		{
			window =  EditorWindow.GetWindow <uSkyTimelineWindow>(true,"Timeline window",true);
			window.autoRepaintOnSceneChange = true;
//			window.maxSize = new Vector2 (Screen.width, 35f); // flickering if resize window
			window.Show ();
		}

		void OnEnable ()
		{
			LoadTimeline ();
		}

		void LoadTimeline ()
		{
			if(uST)
				serObj = new SerializedObject (uST);
			if(serObj != null)
				timeline = serObj.FindProperty ("timeline");
		}

		void RepaintWindow ()
		{
			if (uST && (serObj == null || serObj.targetObject == null)) 
			{
				LoadTimeline ();
				this.Repaint ();
			}
		}

		// When editor compiled script, serObj get destroyed.
		// repaint here.
		void OnFocus () 
		{
			RepaintWindow ();
		}

		// When enter/exit play mode, or loading a new scene, or changed Hierarchy.
		// then this function will be triggered.
		void OnHierarchyChange () 
		{
			if (uST)
				RepaintWindow ();
			else
			// Not working after clicked play, weird...
			if (window)
				window.Close ();
		}

		void OnProjectChange ()
		{
			if (window)
				window.Close ();
		}

		void OnGUI ()
		{
			if (uST)
			{
				EditorGUIUtility.labelWidth = 60f;

				// This prevent the serObj get destroy warning spam in editor.
				// Mostly it happens when load a new scene in editor.
				if (serObj == null || serObj.targetObject == null){
					return;
				}
				serObj.Update ();
				EditorGUILayout.PropertyField(timeline);
				serObj.ApplyModifiedProperties ();
			}
			else 
			{
				EditorGUILayout.HelpBox("Can not find \"uSkyTimeline\" component in the scene.", MessageType.Info );
				GUILayout.Label("- Please make sure an uSkyPro prefab is in current scene and uSkyTimeline enabled." +
				                "\n  (or apply an uSkyTimeline component to a gameobject)" +
								"\n- Re-open this window.");
			}
		}
	}

}