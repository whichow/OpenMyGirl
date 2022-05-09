using UnityEngine;
using usky.Internal;
using usky.PrecomputeUtil;

namespace usky
{
	/// <summary>
	/// This script is responsible for the direct and ambient lighting of the scene
	/// This script needs to be attached to a GameObject.
	/// It will work as standalone component with uSkySun and uSkyMoon.
	/// </summary>
	[ExecuteInEditMode][DisallowMultipleComponent]
	[AddComponentMenu("uSkyPro/uSky Lighting")]
	public class uSkyLighting : MonoBehaviour 
	{	

		[Space()][Tooltip ("The color of the both Sun and Moon light emitted")]
		public Gradient LightColor = new Gradient()
		{
			colorKeys = new GradientColorKey[] {
				new GradientColorKey(new Color32(085, 099, 112, 255), 0.49f),
				new GradientColorKey(new Color32(245, 173, 084, 255), 0.51f),
				new GradientColorKey(new Color32(249, 208, 144, 255), 0.57f),
				new GradientColorKey(new Color32(252, 222, 186, 255), 1.00f),
			},
			alphaKeys = new GradientAlphaKey[] {
				new GradientAlphaKey(1.0f, 0.0f),
				new GradientAlphaKey(1.0f, 1.0f)
			}
		};

		[Range(0f, 8f)][Tooltip ("Brightness of the Sun (directional light)")]
		public float SunIntensity = 1.0f;

		[Range(0f, 1f)][Tooltip ("Brightness of the Moon (directional light). If the Moon Intensity is at 0 (less then 0.01), the Moon light will auto disabled and always disabled at Day time")]
		public float MoonIntensity = 0.2f;

		[HeaderLayout][Tooltip ("Ambient light that shines into the scene.")]
		public AmbientGradientSettings Ambient = new AmbientGradientSettings
		{
			useGradientMode = true,
			
			SkyColor = new Gradient ()
			{
				colorKeys = new GradientColorKey[] {
					new GradientColorKey(new Color32(028, 032, 040, 255), 0.475f),
					new GradientColorKey(new Color32(055, 065, 063, 255), 0.50f),
					new GradientColorKey(new Color32(138, 168, 168, 255), 0.55f),
					new GradientColorKey(new Color32(145, 174, 210, 255), 0.65f),
				},
				alphaKeys = new GradientAlphaKey[] {
					new GradientAlphaKey(1.0f, 0.0f),
					new GradientAlphaKey(1.0f, 1.0f)
				}
			},
			EquatorColor = new Gradient ()
			{
				colorKeys = new GradientColorKey[] {
					new GradientColorKey(new Color32(017, 021, 030, 255), 0.475f),
					new GradientColorKey(new Color32(100, 100, 078, 255), 0.52f),
					new GradientColorKey(new Color32(128, 150, 168, 255), 0.58f),
				},
				alphaKeys = new GradientAlphaKey[] {
					new GradientAlphaKey(1.0f, 0.0f),
					new GradientAlphaKey(1.0f, 1.0f)
				}
			},
			GroundColor = new Gradient ()
			{
				colorKeys = new GradientColorKey[] {
					new GradientColorKey(new Color32(021, 020, 019, 255), 0.48f),
					new GradientColorKey(new Color32(094, 089, 087, 255), 0.55f),
				},
				alphaKeys = new GradientAlphaKey[] {
					new GradientAlphaKey(1.0f, 0.0f),
					new GradientAlphaKey(1.0f, 1.0f)
				}
			}
		};

		uSkySun m_Sun	{ get{ return uSkySun.instance; }}
		uSkyMoon m_Moon	{ get{ return uSkyMoon.instance;}}
		uSkyPro uSP		{ get{ return uSkyPro.instance; }}

		Light sunLight, moonLight;

		[HideInInspector]
		private float normalizedTime, exposureScale;

		struct SkyBrightness
		{
			public float daySky;
			public float nightSky;
		}

		struct LightingColor
		{
			public Color lightColor;
			public Color skyColor;
			public Color equatorColor;
			public Color groundColor;
		}

		SkyBrightness skyBrightness = new SkyBrightness();
		LightingColor lightingColor = new LightingColor();


		void OnEnable ()
		{
			// cache data
			InitLightingParameters (); 
			SetAmbientMode ();
			uSkyInternal.UpdateLightingEvent.AddListener(UpdateLighting);
		}

		void OnDisable ()
		{
			uSkyInternal.UpdateLightingEvent.RemoveListener(UpdateLighting);
		}

		void Start ()
		{
			InitLightComponent ();
			// This component can only find the sun and moon light instances after the OnEnable call
			// So we do the initialization here for light color and intensity.
			UpdateLighting ();
		}

		void Update ()
		{
			// set and check only the light intensity slider value
			SetLightingState ();
		}

		void InitLightComponent ()
		{
			if (m_Sun)
				sunLight = m_Sun.SunLight;
		
			if (m_Moon)
				moonLight = m_Moon.MoonLight;
		}

		// Update is called by UpdateLightingEvent
		public void UpdateLighting ()
		{
			ComputeLightingParams ();

			if (sunLight == null || moonLight == null)
				InitLightComponent ();

			if (sunLight)
			{
				sunLight.intensity = SunIntensity;
				sunLight.color = lightingColor.lightColor * skyBrightness.daySky;
//				sunLight.color = SunExtinction() ;
				// enable on Day, disable at Night.
				sunLight.enabled = (normalizedTime > 0.48f /* || MoonIntensity < 0.01f */) ? true : false;
			}

			if (moonLight) 
			{
				moonLight.intensity = MoonIntensity;
				moonLight.color = lightingColor.lightColor * skyBrightness.nightSky * MoonFade();
				// Moon Intensity > 0.01 it will enable at Night, always disabled at Day time
				moonLight.enabled = (normalizedTime < 0.50f && MoonIntensity > 0.01f) ? true : false;
			}

			// Ambient
			if (RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.Trilight && Ambient.useGradientMode)
				AmbientGradientUpdate ();
//			else
//				RenderSettings.ambientLight = lightingColor.lightColor; // update it for cloud color

			// clouds material
			UpdateMaterialUniforms ();

//			Debug.Log ("Lighthing updated!");
//			Debug.Log ("Lighthing - NormalizedTime :    " + NormalizedTime);
		}

		void ComputeLightingParams ()
		{
			normalizedTime 				= uSkyInternal.NormalizedTime (m_Sun, m_Moon); 
			exposureScale				= (uSP)? Mathf.Pow( uSP.Exposure, 0.4f) : 1f; 

			lightingColor.lightColor	= LightColor.Evaluate (normalizedTime) * exposureScale;
			lightingColor.skyColor		= Ambient.SkyColor.Evaluate (normalizedTime)* exposureScale; 
			lightingColor.equatorColor 	= Ambient.EquatorColor.Evaluate (normalizedTime)* exposureScale; 
			lightingColor.groundColor	= Ambient.GroundColor.Evaluate (normalizedTime) * exposureScale;

			skyBrightness.daySky		= Mathf.Clamp01 (DayTimeBrightness() * 4);
			skyBrightness.nightSky		= NightTimeBrightness(); 
		}


		void AmbientGradientUpdate ()
		{
			RenderSettings.ambientSkyColor		= lightingColor.skyColor;
			RenderSettings.ambientEquatorColor	= lightingColor.equatorColor;
			RenderSettings.ambientGroundColor	= lightingColor.groundColor;
		}

		// mainly for clouds material
		void UpdateMaterialUniforms ()
		{
			float currentLightIntensity	= Mathf.Lerp ( MoonIntensity, SunIntensity, Mathf.Clamp01 (DayTimeBrightness()*1.2f));
			// slightly delayed sunset time for clouds shading
			float t = Mathf.Clamp01 ((normalizedTime + 4e-3f) * 1.05f);
			Shader.SetGlobalVector ("_uSkyLightColor", LightColor.Evaluate (t) * (exposureScale * Mathf.Pow ( currentLightIntensity, 2.2f)));
		}
		
		void SetAmbientMode ()
		{
			if(Ambient.useGradientMode)
				RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
		}
		
		void OnValidate() 
		{
			UpdateLighting (); // keep update the gradient color in Editor
			
			SetAmbientMode ();
		}

		// compute sun color via precomputed Transmittance texture
		// TODO need to click the play button to load the texture
		Color SunTransmittance ()
		{
			if (uSkyPrecomputeUtil.Transmittance2D != null) {
				Texture2D tex = uSkyPrecomputeUtil.Transmittance2D;
				float uMu = Mathf.Atan ((SunDirUp + 0.15f) / (1.0f + 0.15f) * Mathf.Tan (1.5f)) / 1.5f;
				int x = Mathf.FloorToInt (uMu * tex.width);
				return tex.GetPixel (x, 0);
			} else
				return Color.white;
		}

		float SunDirUp {
			get { return (m_Sun) ? -m_Sun.transform.forward.y : 0.766f; }
		}

		float MoonDirUp {
			get { return (m_Moon)? -m_Moon.transform.forward.y : 0.766f; }
		}

	#region Copied functions from uSkyPro
		float DayTimeBrightness () { 
			// DayTime : Based on Bruneton's uMuS Linear function ( modified )
			return Mathf.Clamp01 (Mathf.Max (SunDirUp + 0.2f, 0.0f) / 1.2f);
		}
		
		public float NightTimeBrightness () { 
			return 1 - DayTimeBrightness(); 
		}
		
		float MoonFade () { 
			return (MoonDirUp > 0f)? Mathf.Max ( Mathf.Clamp01 ((MoonDirUp - 0.1f) * Mathf.PI)* NightTimeBrightness() - DayTimeBrightness(), 0f): 0f;  
		}
	#endregion

// -----------------------------------------------------------
		// Check if the settings are dirty

		[HideInInspector]
		float m_SunIntensity, m_MoonIntensity;

		void InitLightingParameters ()
		{
			m_SunIntensity = SunIntensity;
			m_MoonIntensity = MoonIntensity;
		}

		void SetLightingState ()
		{
			SetSunIntensity (SunIntensity);
			SetMoonIntensity (MoonIntensity);
		}

		void SetSunIntensity (float NewIntensity)
		{
			if (m_SunIntensity != NewIntensity) {
				m_SunIntensity = NewIntensity;
				uSkyInternal.MarkLightingStateDirty ();
			}
		}

		void SetMoonIntensity (float NewIntensity)
		{
			if (m_MoonIntensity != NewIntensity) {
				m_MoonIntensity = NewIntensity;
				uSkyInternal.MarkLightingStateDirty ();
			}
		}


	}
}