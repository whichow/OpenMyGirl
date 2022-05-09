// This script controls the uSkyTimeline script in "Default" type only (in Play mode).
// Support Mouse Drag and Touch input for mobile devices.
// USAGE: This script can be applied to any gameObject.

using UnityEngine;
using UnityEngine.EventSystems;

namespace usky
{
	[AddComponentMenu("uSkyPro/Other/Mouse Drag Timeline Controller")]
	public class MouseDragTimelineController : MonoBehaviour {

		public float MoveSpeed = 1.0f;

		private float altitude = 0f;
		private float azimuth = 0f;

		uSkyTimeline uST { get { return uSkyTimeline.instance; } }
	/*
		void Start () {
			// set uSkyTimeline Mode to "Default"
			if (uST && uST.Type == TimeSettingsMode.Realistic) 
			{
				uST.Type = TimeSettingsMode.Default;
		#if UNITY_EDITOR
			Debug.Log ("Note : Force to set the Timeline \"Type\" to \"Default\" for MouseDragTimelineController script");
		#endif
			}
		}
	*/
		// Update is called once per frame
		void Update () {

			if (!uST)
				return;

			if ( EventSystem.current != null){
				if ( EventSystem.current.IsPointerOverGameObject())
					return;
			}
			// Touch input
			#if (UNITY_IOS || UNITY_ANDROID) && !UNITY_EDITOR
			if ( Input.touchCount == 1 )  
			{	
				// Assume using landscape orientation on build
				altitude = Input.GetTouch(0).deltaPosition.y * Time.smoothDeltaTime * Speed * 0.25f;
				azimuth = Input.GetTouch(0).deltaPosition.x * Time.smoothDeltaTime * Speed * 2f;

				UpdateTimelineAndSunDirection (azimuth, altitude);
			}
			#else
			// Mouse input
			if ( Input.GetMouseButton (0) && !Input.GetMouseButton (1))  
			{	
				altitude = Input.GetAxis ("Mouse Y") * Time.smoothDeltaTime * MoveSpeed ;
				azimuth = Input.GetAxis ("Mouse X") * Time.smoothDeltaTime * MoveSpeed * 20f;

				UpdateTimelineAndSunDirection (azimuth, altitude);
			}
			#endif 

		}

		void UpdateTimelineAndSunDirection (float x, float y)
		{
			uST.Timeline = uST.Timeline - y;
			uST.SunDirection = uST.SunDirection + x;

			uST.Latitude = Mathf.Clamp( uST.Latitude - azimuth, -90.0f, 90.0f);	
//			uST.Longitude = uST.Longitude + Mathf.Asin(Mathf.Sin(uST.Latitude));

		}
	}
}