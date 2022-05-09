using UnityEngine;
using UnityEngine.Events;

namespace usky.Internal
{
	/// <summary>
	/// This script cached all the parameters internally for uSkyPro package.
	/// In general you should not access to this script, unless you know what you are doing.
	/// In most case you should just call uSkyPro.instance instead.
	/// </summary>
	public static class uSkyInternal 
	{
	#region uSkyEvent
		// Unity Events ------------------------------------------------------------------------------------------------------------------------------------------------------------------
		// Events name														| Driven script					| Call function					|| Driver : Settings (Event Trigger)
		//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		public static UnityEvent UpdatePrecomputeEvent	= new UnityEvent(); // uSkyPro						: UpdatePrecomputeData()		|| uSkyPro : Precomputed Params
		public static UnityEvent UpdateAtmosphereEvent	= new UnityEvent();	// uSkyPro	 					: UpdateMaterialUniform()		|| uSkyPro (All)
																			// uSkyReflectionProbeUpdater	: RenderReflectionProbe()		||
																			// uSkyFogGradient				: UpdateUnityFog()				||
		public static UnityEvent UpdateTimelineEvent	= new UnityEvent(); // uSkyTimeline					: UpdateSunAndMoon()			|| uSkyTimeline (All), uSkyPro : NightMode
		public static UnityEvent UpdateCycleEvent		= new UnityEvent(); // uSkyTimeline					: SetTimelineState()			|| uSkyTimeline : Timeline
		public static UnityEvent UpdateLightingEvent	= new UnityEvent(); // uSkyLighting					: UpdateLighting()				|| uSkyLighting : (Sun and Moon) Intensity,  uSkyPro : Exposure
		public static UnityEvent UpdateProbeEvent		= new UnityEvent(); // uSkyReflectionProbeUpdater	: RenderReflectionProbe()		|| uSkyPro (All), uSkyClouds2D (All - editor only)

		/// <summary>
		/// Trigger the event for Sun and Moon position update ()
		/// </summary>
		public static void MarkTimelineStateDirty ()
		{
			if(UpdateTimelineEvent != null)
				UpdateTimelineEvent.Invoke ();
		}

		/// <summary>
		/// Trigger the event for ActualTime to Timeline in uSkyTimeline
		/// </summary>
		public static void MarkCycleStateDirty ()
		{
			if (UpdateCycleEvent != null)
				UpdateCycleEvent.Invoke ();
		}

		/// <summary>
		/// Trigger the event for Sun and Moon light color and intensity update.
		/// </summary>
		public static void MarkLightingStateDirty ()
		{
			if (UpdateLightingEvent != null )
				UpdateLightingEvent.Invoke ();
		}

		/// <summary>
		/// Trigger the event for Skybox and Atmospheric Scattering update.
		/// </summary>
		public static void MarkAtmosphereStateDirty ()
		{
			if (UpdateAtmosphereEvent != null)
				UpdateAtmosphereEvent.Invoke ();
		}

		/// <summary>
		/// Trigger the event for Precomputed Data update.
		/// </summary>
		public static void MarkPrecomputedStateDirty ()
		{
			if (UpdatePrecomputeEvent != null)
				UpdatePrecomputeEvent.Invoke ();
		}

		/// <summary>
		/// Trigger the event for Reflection probe cubemap rendering
		/// </summary>
		public static void MarkProbeStateDirty ()
		{
			if (UpdateProbeEvent != null)
				UpdateProbeEvent.Invoke ();
		}

		public static void RemoveAllEventListeners ()
		{
			UpdateTimelineEvent.RemoveAllListeners ();
			UpdateLightingEvent.RemoveAllListeners ();
			UpdateAtmosphereEvent.RemoveAllListeners ();
			UpdatePrecomputeEvent.RemoveAllListeners ();
		}
	#endregion

	#region Common functions

		/// <summary>
		/// Normalized value of current altitude position of sun
		/// (Range 0.0 to 1.0)
		/// 1	= the sun is at the zenith.
		/// 0.5	= the sun is at the horizon.
		/// 0	= the sun is at the bottom.
		/// </summary>
		public static float NormalizedTime (uSkySun m_Sun, uSkyMoon m_Moon)
		{ 
			float value = 1f;
			if (m_Sun)
				value = -m_Sun.transform.forward.y * 0.5f + 0.5f;
			else 
			if (m_Moon)
				value = m_Moon.transform.forward.y * 0.5f + 0.5f;

			return value;
		}

		public static void SetSpaceAndStarsRotation (Quaternion rotation) 
		{
			Matrix4x4 m_SpaceMatrix = Matrix4x4.identity;
			m_SpaceMatrix.SetTRS ( Vector3.zero, rotation, Vector3.one );
			Shader.SetGlobalMatrix ("_StarRotationMatrix" ,	(m_NightSkyMode == 1) ? m_SpaceMatrix			: Matrix4x4.identity);
			Shader.SetGlobalMatrix ("_SpaceRotationMatrix", (m_NightSkyMode == 1) ? m_SpaceMatrix.inverse	: Matrix4x4.identity);
		}


	#endregion

		// uSkyPro Parameters
		internal static float	m_Exposure;
		internal static float	m_MieScattering;
		internal static float	m_SunAnisotropyFactor;
		internal static float	m_SunSize;

		internal static float	m_StarIntensity;
		internal static float	m_OuterSpaceIntensity;
		internal static float	m_MoonSize;
		internal static float	m_GroundOffset;
		internal static float	m_AltitudeScale;

		internal static Color	m_GroundColor;
		internal static Color	m_NightZenithColor;
		internal static Color	m_NightHorizonColor;
		internal static Color	m_MoonInnerCorona;
		internal static Color	m_MoonOuterCorona;

		internal static int 	m_NightSkyMode;

		internal static bool	m_DisableSkyboxOcean;
		internal static bool	m_HDRMode;

		// Precomputed Parameters
		internal static float	m_AtmosphereThickness;
		internal static Vector3 m_Wavelengths;
		internal static Color	m_SkyTint;
		internal static int		m_InscatterAltitudeSample;

		// Timeline Parameters
		internal static int		m_TimeMode;
		internal static float	m_Timeline;

		internal static float	m_SunDirection;
		internal static float	m_SunEquatorOffset;
		internal static float	m_MoonPositionOffset;
			
		internal static	float	m_Latitude;
		internal static	float	m_Longitude;

		internal static int 	m_Day;
		internal static int 	m_Month;
		internal static int 	m_Year;
		internal static int 	m_GMTOffset;

		#region uSkyPro Parameters
		public static void InitAtmosphereParameters (uSkyPro uSP)
		{
			m_Exposure					= uSP.Exposure;
			m_MieScattering				= uSP.MieScattering;
			m_SunAnisotropyFactor 		= uSP.SunAnisotropyFactor;
			m_SunSize					= uSP.SunSize;

			m_NightSkyMode				= (int)uSP.NightMode;
			m_NightZenithColor 			= uSP.NightZenithColor;
			m_NightHorizonColor			= uSP.NightHorizonColor;
			m_StarIntensity				= uSP.StarIntensity;
			m_OuterSpaceIntensity 		= uSP.OuterSpaceIntensity;
			m_MoonInnerCorona			= uSP.MoonInnerCorona;
			m_MoonOuterCorona			= uSP.MoonOuterCorona;
			m_MoonSize					= uSP.MoonSize;

//			GroundColor					= uSP.GroundColor;
			m_GroundOffset				= uSP.GroundOffset;
			m_AltitudeScale				= uSP.AltitudeScale;
			m_DisableSkyboxOcean		= uSP.DisableSkyboxOcean;
			m_HDRMode					= uSP.HDRMode;

			// Precomputed params
			m_AtmosphereThickness		= uSP.AtmosphereThickness;
			m_Wavelengths				= uSP.Wavelengths;
			m_SkyTint					= uSP.SkyTint;
			m_InscatterAltitudeSample	= (int)uSP.InscatterAltitudeSample;
		}

		public static void SetNightSkyMode (int NewNightSkyMode)
		{
			if (m_NightSkyMode != NewNightSkyMode) {
				m_NightSkyMode = NewNightSkyMode;
				// trigger Timeline to update the Space and Stars rotation
				MarkTimelineStateDirty ();
				// Update moon element in skybox
				MarkAtmosphereStateDirty ();
			}
		}

		public static void SetSkyboxOcean (bool SkyboxOcean)
		{
			if (m_DisableSkyboxOcean != SkyboxOcean) {
				m_DisableSkyboxOcean = SkyboxOcean;
				MarkAtmosphereStateDirty ();
			}
		}

		public static void SetHDRMode (bool NewHDRMode)
		{
			if (m_HDRMode != NewHDRMode) {
				m_HDRMode = NewHDRMode;
				MarkProbeStateDirty ();
			}
		}
		public static void SetAtmosphereParameterState (uSkyPro uSP) 
		{
			// uSkyPro Parameters
			SetExposure					(uSP.Exposure);
			SetMieScattering			(uSP.MieScattering);
			SetSunAnisotropyFactor		(uSP.SunAnisotropyFactor);
			SetSunSize					(uSP.SunSize);

//			SetNightSkyMode				((int)uSP.NightMode);
			SetNightZenithColor			(uSP.NightZenithColor);
			SetNightHorizonColor		(uSP.NightHorizonColor);
			SetStarIntensity			(uSP.StarIntensity);
			SetOuterSpaceIntensity		(uSP.OuterSpaceIntensity);
			SetMoonInnerCorona			(uSP.MoonInnerCorona);
			SetMoonOuterCorona			(uSP.MoonOuterCorona);
			SetMoonSize					(uSP.MoonSize);

//			SetGroundColor				(uSP.GroundColor);
			SetGroundOffset				(uSP.GroundOffset);
			SetAltitudeScale			(uSP.AltitudeScale);
			SetSkyboxOcean 				(uSP.DisableSkyboxOcean);

			// Precomputed params
			SetAtmosphereThickness		(uSP.AtmosphereThickness);
			SetWavelengths				(uSP.Wavelengths);
			SetSkyTint					(uSP.SkyTint);
			SetInscatterAltitudeSample	((int)uSP.InscatterAltitudeSample);

		}

		static void SetExposure (float NewExposure)
		{
			if (m_Exposure != NewExposure) {
				m_Exposure = NewExposure;
				MarkAtmosphereStateDirty ();
				MarkLightingStateDirty ();
			}
		}

		static void SetMieScattering (float NewMieScattering)
		{
			if (m_MieScattering != NewMieScattering){
				m_MieScattering = NewMieScattering;
				MarkAtmosphereStateDirty ();			
			}
		}
	
		static void SetSunAnisotropyFactor (float NewSunAnisotropyFactor)
		{
			if (m_SunAnisotropyFactor != NewSunAnisotropyFactor){
				m_SunAnisotropyFactor = NewSunAnisotropyFactor;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetSunSize (float NewSunSize)
		{
			if (m_SunSize != NewSunSize) {
				m_SunSize = NewSunSize;
				MarkAtmosphereStateDirty ();
			}
		}

		static void SetNightZenithColor (Color NewNightZenithColor)
		{
			if (m_NightZenithColor != NewNightZenithColor){
				m_NightZenithColor = NewNightZenithColor;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetNightHorizonColor (Color NewNightHorizonColor)
		{
			if (m_NightHorizonColor != NewNightHorizonColor){
				m_NightHorizonColor = NewNightHorizonColor;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetStarIntensity (float NewStarIntensity)
		{
			if (m_StarIntensity != NewStarIntensity){
				m_StarIntensity = NewStarIntensity;
				Shader.SetGlobalFloat ("_StarIntensity", m_StarIntensity * 5f);
			}
		}
		
		static void SetOuterSpaceIntensity (float NewOuterSpaceIntensity)
		{
			if (m_OuterSpaceIntensity != NewOuterSpaceIntensity) {
				m_OuterSpaceIntensity = NewOuterSpaceIntensity;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetMoonInnerCorona (Color NewMoonInnerCorona)
		{
			if (m_MoonInnerCorona != NewMoonInnerCorona){
				m_MoonInnerCorona = NewMoonInnerCorona;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetMoonOuterCorona (Color NewMoonOuterCorona)
		{
			if (m_MoonOuterCorona != NewMoonOuterCorona){
				m_MoonOuterCorona = NewMoonOuterCorona;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetMoonSize (float NewMoonSize)
		{
			if (m_MoonSize != NewMoonSize) {
				m_MoonSize = NewMoonSize;
				MarkAtmosphereStateDirty ();
			}
		}
		
		static void SetGroundColor (Color NewGroundColor)
		{
			if (m_GroundColor != NewGroundColor) {
				m_GroundColor = NewGroundColor;
				MarkAtmosphereStateDirty ();
			}
		}
		static void SetGroundOffset (float NewGroundOffset)
		{
			if (m_GroundOffset != NewGroundOffset) {
				m_GroundOffset = NewGroundOffset;
				MarkAtmosphereStateDirty ();
//				Shader.SetGlobalFloat ("_uSkyGroundOffset", GroundOffset * (float)InscatterAltitudeSample);
			}
		}

		static void SetAltitudeScale (float NewAltitudeScale)
		{
			if (m_AltitudeScale != NewAltitudeScale){
				m_AltitudeScale = NewAltitudeScale;
				MarkAtmosphereStateDirty ();
//				Shader.SetGlobalFloat ("_uSkyAltitudeScale", AltitudeScale);
			}
		}
			

// Precomputed parameters ----------------------

		static void SetAtmosphereThickness(float NewAtmosphereThickness)
		{
			if (m_AtmosphereThickness != NewAtmosphereThickness) {
				m_AtmosphereThickness = NewAtmosphereThickness;
				MarkPrecomputedStateDirty();
				Shader.SetGlobalFloat ("_uSkyAtmosphereThickness", m_AtmosphereThickness); // fix the artifact for deferred
				MarkProbeStateDirty();
			}
		}
		
		static void SetWavelengths (Vector3 NewWavelengths)
		{
			if (m_Wavelengths != NewWavelengths) {
				m_Wavelengths = NewWavelengths;
				MarkPrecomputedStateDirty();
				MarkProbeStateDirty();
			}
		}
		
		static void SetSkyTint (Color NewSkyTint)
		{
			if (m_SkyTint != NewSkyTint) {
				m_SkyTint = NewSkyTint;
				MarkPrecomputedStateDirty();
				MarkProbeStateDirty();
			}
		}

		static void SetInscatterAltitudeSample(int NewInscatterAltitudeSample)
		{
			if (m_InscatterAltitudeSample != NewInscatterAltitudeSample) {
				m_InscatterAltitudeSample = NewInscatterAltitudeSample;
				MarkPrecomputedStateDirty();				
				Shader.SetGlobalFloat ("_uSkyGroundOffset", m_GroundOffset * (float)m_InscatterAltitudeSample);
				MarkProbeStateDirty();
			}
		}

		#endregion

// TimeLine Settings ------------------------

		#region TimeLine Settings

		public static void InitTimelineParameters (uSkyTimeline uST){
			m_TimeMode				= (int)uST.Type;
			m_Timeline				= uST.Timeline;

			m_SunDirection			= uST.SunDirection;
			m_SunEquatorOffset		= uST.SunEquatorOffset;
			m_MoonPositionOffset	= uST.MoonPositionOffset;

			m_Latitude				= uST.Latitude;
			m_Longitude				= uST.Longitude;

			m_Day					= uST.Day;
			m_Month					= uST.Month;
			m_Year					= uST.Year;
			m_GMTOffset				= uST.GMTOffset;
		}

		public static void SetTimeMode (int NewTimeMode)
		{
			if (m_TimeMode != NewTimeMode) {
				m_TimeMode = NewTimeMode;
				MarkTimelineStateDirty();
			}
		}

		public static void SetTimeline (float NewTimeline)
		{
			if (m_Timeline != NewTimeline) {
				m_Timeline = NewTimeline;
				MarkCycleStateDirty ();
				MarkTimelineStateDirty();
			}
		}

// Default timeline settings --------------------------

		public static void SetTimelineSettingState (DefaultTimelineSettings Setting)
		{
			SetSunDirection (Setting.sunDirection);
			SetSunEquatorOffset (Setting.sunEquatorOffset);
			SetMoonPositionOffset (Setting.moonPositionOffset);

		}

		public static void SetSunDirection (float NewSunDirection)
		{
			if (m_SunDirection != NewSunDirection) {
				m_SunDirection = NewSunDirection;
				MarkTimelineStateDirty();
			}
		}
		public static void SetSunEquatorOffset (float NewEquatorOffset)
		{
			if (m_SunEquatorOffset != NewEquatorOffset) {
				m_SunEquatorOffset = NewEquatorOffset;
				MarkTimelineStateDirty();
			}
		}
		public static void SetMoonPositionOffset (float NewMoonPositionOffset)
		{
			if (m_MoonPositionOffset != NewMoonPositionOffset) {
				m_MoonPositionOffset = NewMoonPositionOffset;
				MarkTimelineStateDirty();
			}
		}
// Realistic timeline settings --------------------------

		public static void SetTimelineSettingState (RealisticTimelineSettings Setting)
		{
			SetLatitude (Setting.latitude);
			SetLongitude (Setting.longitude);
			SetDay (Setting.day);
			SetMonth (Setting.month);
			SetYear (Setting.year); 
			SetGMTOffset (Setting.GMTOffset);

		}

		static void SetLatitude (float NewLatitude)
		{
			if (m_Latitude != NewLatitude) {
				m_Latitude = NewLatitude;
				MarkTimelineStateDirty();
			}
		}
		static void SetLongitude (float NewLongitude)
		{
			if (m_Longitude != NewLongitude) {
				m_Longitude = NewLongitude;
				MarkTimelineStateDirty();
			}
		}
		static void SetDay (int NewDay)
		{
			if (m_Day != NewDay) {
				m_Day = NewDay;
				MarkTimelineStateDirty();
			}
		}
		static void SetMonth (int NewMonth)
		{
			if (m_Month != NewMonth) {
				m_Month = NewMonth;
				MarkTimelineStateDirty();
			}
		}
		static void SetYear (int NewYear)
		{
			if (m_Year != NewYear) {
				m_Year = NewYear;
				MarkTimelineStateDirty();
			}
		}
		static void SetGMTOffset (int NewGMTOffset)
		{
			if (m_GMTOffset != NewGMTOffset) {
				m_GMTOffset = NewGMTOffset;
				MarkTimelineStateDirty();
			}
		}
		#endregion

// Clouds 2D  ----------------------------------------------
		#region Clouds 2D
	/*
		static Material m_Clouds2DMaterial;
		
		// Get the value from material and check if its dirty
		// Skip animation RotateSpeed parameters
		static int		AmbientSource,		m_AmbientSource;
		static float	Attenuation,		m_Attenuation;
		static float	StepSize,			m_StepSize;
		static float	AlphaSaturation,	m_AlphaSaturation;
		static float	SunColorMultiplier,	m_SunColorMultiplier;
		static float	SkyColorMultiplier,	m_SkyColorMultiplier;
		static float	CloudsDensity2D,	m_CloudsDensity2D;
		static float	ScatterMultiplier2D,m_ScatterMultiplier2D;
		static int		MappingMode,		m_MappingMode;
		static Texture	Clouds2DTex,		m_Clouds2DTex;
		
		
		static void GetValueFromMaterial (Material mat)
		{
			AmbientSource		= mat.GetInt ("_AmbientSource");
			Attenuation			= mat.GetFloat ("_Attenuation");
			StepSize			= mat.GetFloat ("_StepSize");
			AlphaSaturation		= mat.GetFloat ("_AlphaSaturation");
			SunColorMultiplier	= mat.GetFloat ("_LightColorMultiplier");
			SkyColorMultiplier	= mat.GetFloat ("_SkyColorMultiplier");
			CloudsDensity2D		= mat.GetFloat ("_Mask");
			ScatterMultiplier2D = mat.GetFloat ("_ScatterMultiplier");
			MappingMode			= mat.GetInt ("_Mapping");
			Clouds2DTex			= mat.GetTexture ("_CloudSampler");
			
		}
		
		// Only update the Reflection Probe if its dirty
		public static void SetCloudsReflectionProbeState (Material mat)
		{
			if (mat == null || (mat.shader != Shader.Find ("uSkyPro/Clouds 2D") 
			                 && mat.shader != Shader.Find ("uSkyPro/Clouds 2D Turbulence")))
				return;
			
			GetValueFromMaterial (mat);
			
			SetClouds2DMaterial	(mat);
			SetAmbientSource (AmbientSource);
			SetAttenuation (Attenuation);
			SetStepSize (StepSize);
			SetAlphaSaturation (AlphaSaturation);
			SetSunColorMultiplier (SunColorMultiplier);
			SetSkyColorMultiplier (SkyColorMultiplier);
			SetCloudsDensity2D (CloudsDensity2D);
			SetScatterMultiplier2D (ScatterMultiplier2D);
			SetMappingMode (MappingMode);
			SetClouds2DTex (Clouds2DTex);
		}
		
		static void SetClouds2DMaterial (Material NewClouds2DMaterial)
		{
			if (m_Clouds2DMaterial != NewClouds2DMaterial) {
				m_Clouds2DMaterial = NewClouds2DMaterial;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetAmbientSource (int NewAmbientSource)
		{
			if (m_AmbientSource != NewAmbientSource) {
				m_AmbientSource = NewAmbientSource;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetAttenuation (float NewAttenuation)
		{
			if (m_Attenuation != NewAttenuation) {
				m_Attenuation = NewAttenuation;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetStepSize (float NewStepSize)
		{
			if (m_StepSize != NewStepSize) {
				m_StepSize = NewStepSize;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetAlphaSaturation (float NewAlphaSaturation)
		{
			if (m_AlphaSaturation != NewAlphaSaturation) {
				m_AlphaSaturation = NewAlphaSaturation;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetSunColorMultiplier (float NewSunColorMultiplier)
		{
			if (m_SunColorMultiplier != NewSunColorMultiplier) {
				m_SunColorMultiplier = NewSunColorMultiplier;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetSkyColorMultiplier (float NewSkyColorMultiplier)
		{
			if (m_SkyColorMultiplier != NewSkyColorMultiplier) {
				m_SkyColorMultiplier = NewSkyColorMultiplier;
				uSkyInternal.MarkProbeStateDirty();
			}
		}

		static void SetCloudsDensity2D (float NewCloudsDensity2D)
		{
			if (m_CloudsDensity2D != NewCloudsDensity2D) {
				m_CloudsDensity2D = NewCloudsDensity2D;
				uSkyInternal.MarkProbeStateDirty();
			}
		}

		static void SetScatterMultiplier2D (float NewScatterMultiplier2D)
		{
			if (m_ScatterMultiplier2D != NewScatterMultiplier2D) {
				m_ScatterMultiplier2D = NewScatterMultiplier2D;
				uSkyInternal.MarkProbeStateDirty();
			}
		}

		static void SetMappingMode (int NewMappingMode)
		{
			if (m_MappingMode != NewMappingMode) {
				m_MappingMode = NewMappingMode;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
		
		static void SetClouds2DTex (Texture NewClouds2DTex)
		{
			if (m_Clouds2DTex != NewClouds2DTex) {
				m_Clouds2DTex = NewClouds2DTex;
				uSkyInternal.MarkProbeStateDirty();
			}
		}
	*/
		#endregion
	}
}