//	The reflection update sequence controls via Event call.
//	Usage : Apply this script to the Reflection Probe gameobject.

using UnityEngine;
using UnityEngine.Rendering;
using usky.Internal;

namespace usky
{
	/// <summary>
	/// uSky reflection probe updater and controls update sequence behaviour for reflection.
	/// </summary>
	[ExecuteInEditMode][DisallowMultipleComponent]
	[AddComponentMenu("uSkyPro/uSky ReflectionProbe Updater")]
	public class uSkyReflectionProbeUpdater : MonoBehaviour {

		[Tooltip("The Time Slicing setting can be different between in Editor and Play Mode (or at RunTime)," +
			"\n\nRecommended using \"No Time Slicing\" in Editor for correctly generate reflection cubemap." +
			"\n\nOnly requires to set \"No Time Slicing\" at Runtime if the probe needed to update per frame. " +
			"\n(uSkyTimeline / Day Night Cycle : Stepped Interval = 0)")]
		public ReflectionProbeTimeSlicingMode RuntimeTimeSlicing = ReflectionProbeTimeSlicingMode.AllFacesAtOnce;

		private ReflectionProbe TheProbe;

		void OnEnable ()
		{
			TheProbe = GetComponent<ReflectionProbe> ();
			uSkyInternal.UpdateProbeEvent.AddListener	(RenderReflectionProbe);
		}

		void OnDisable ()
		{
			uSkyInternal.UpdateProbeEvent.RemoveListener(RenderReflectionProbe);
		}

		void Start () 
		{
			if (TheProbe == null)
				enabled = false;
			
			TheProbe.mode = ReflectionProbeMode.Realtime;
			TheProbe.refreshMode = ReflectionProbeRefreshMode.ViaScripting;

			if ( Application.isPlaying )
				TheProbe.timeSlicingMode = RuntimeTimeSlicing;
			else
				TheProbe.timeSlicingMode = ReflectionProbeTimeSlicingMode.NoTimeSlicing;
		}

		// This function is called by UpdateProbeEvent
		void RenderReflectionProbe ()
		{
			TheProbe.RenderProbe ();
		}

	}
}