using UnityEngine;
using usky.Internal;

namespace usky
{
	[ExecuteInEditMode][DisallowMultipleComponent]
	[AddComponentMenu("uSkyPro/uSky Moon")]
	public class uSkyMoon : MonoBehaviour {
		public static uSkyMoon instance;

		new public Transform	transform { get; private set; }
		public Light		MoonLight { get; private set; }
		
		void OnEnable() {
			if(instance) {
				Debug.LogErrorFormat("Not setting 'uSkyMoon.instance' because '{0}' is already active!", instance.name);
				return;
			}

			this.transform = base.transform;
			MoonLight = GetComponent<Light>();
			instance = this;
		}

		void OnDisable() {
			if(instance == null) {
				Debug.LogErrorFormat("'uSkyMoon.instance' is already null when disabling '{0}'!", this.name);
				return;
			}
		
			if(instance != this) {
				Debug.LogErrorFormat("Not UNsetting 'uSkyMoon.instance' because it points to someone else '{0}'!", instance.name);
				return;
			}

			// Unity version 5.1.2 or newer
			GetComponent<Light>().RemoveAllCommandBuffers();

			instance = null;
		}

		// Takeover the events triggering if detected uSkyTimeline, uSkyPro and uSkySun instances not in current scene
		void Update ()
		{
			if (uSkyTimeline.instance != null && uSkyPro.instance != null && uSkyPro.instance.NightMode == NightModes.Rotation)
				return;
			else
				// Update the moon position in skybox.
				CheckMoonTransformState ();
		}

		void CheckMoonTransformState ()
		{
			if (this.transform.hasChanged && instance == this) 
			{
				if (uSkyTimeline.instance == null)
					uSkyInternal.MarkLightingStateDirty ();

				if (uSkyPro.instance != null)
					uSkyInternal.MarkAtmosphereStateDirty ();
				else{
					uSkyInternal.MarkAtmosphereStateDirty ();
					// useful only if the scene has sky clouds
					uSkyInternal.MarkProbeStateDirty ();
				}
				this.transform.hasChanged = false;
			}
		}
	}
}
