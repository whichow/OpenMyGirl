using UnityEngine;

namespace usky
{
#if UNITY_5_4_OR_NEWER
	[ImageEffectAllowedInSceneView]
#endif
	[ExecuteInEditMode]
	[RequireComponent (typeof(Camera))]
	[AddComponentMenu ("uSkyPro/uSky LightShafts")]
	public class uSkyLightShafts : MonoBehaviour
	{
		public enum LightShaftsResolution
		{
			Low,
			Normal, // default
			High,
		}

		public enum DebugViewMode
		{
			None,	// default
			ShaftMask,
			OcclusionMask,
			OcclusionDepthRange,
		}

		[Tooltip ("Debug View Mode")]
		public DebugViewMode DebugMode = DebugViewMode.None;

		[Tooltip("\"Low\" is Quarter-Resolution. \r\n\"Normal\" is Half-Resolution: Default setting. \r\n\"High\" is Full-Resolution.")]
		public LightShaftsResolution resolution = LightShaftsResolution.Normal;

		private uSkySun m_Sun					{ get { return uSkySun.instance;} }
		private Transform LightShaftsTransform;	// assign to m_Sun.transform

		[Header ("Light Shaft Bloom")]
		[Range (0f, 10f)][Tooltip("Scales additive color near the light source, A value of 0 will result in no additive term.")]
		public float BloomScale = 1f;

		[Range (0f, 10f)][Tooltip("Control the Bloom's radius size. 1 is the default value, higher value will create larger shafts' radius")]
		public float BloomRadius = 1f;

		[Range (0f, 1f)][Tooltip("Scene (RGB) color luminance must be larger than this to create bloom in light shafts.")]
		public float BloomThreshold = 0f;

		[Tooltip("Multiplies against scene color to create the bloom color.")]
		public Color BloomTint = Color.white;

		[Header ("Light Shaft Occlusion")]
		[Tooltip ("Everything closer to the camera than this distance will occlude light shafts." +
			"\r\n\nSet this value to halve of the camera far clipping plane will be a good default value.")]
		public float OcclusionDepthRange = 500f;

		[Range (0f, 1f)][Tooltip("Control how dark is the occlusion masking is, a value of 1 result in no darking term.")]
		public float OcclusionMaskDarkness = 0.3f;

	//	[Range(0f,1f)]
	//	public float useSkyBoxAlpha = 0.5f;
	//	public bool useDepthTexture = true;

		private Camera cam;
		private bool isSupported = true;
		private int DownsampleFactor = 4;

		[HideInInspector] public Shader m_LightShaftsComposite;
		private Material m_LightShaftsMaterial;

		protected bool CheckSupport ()
		{
			// support ImageEffects and support depth?
			if (!SystemInfo.supportsImageEffects || !SystemInfo.SupportsRenderTextureFormat (RenderTextureFormat.Depth)) {
				return false;
			} else
				return true;
		}

		// Check if missing shader asset
		protected void OnEnable ()
		{
			if(m_LightShaftsComposite == null || m_LightShaftsComposite != Shader.Find ("Hidden/uSkyLightShaftsComposite"))
				m_LightShaftsComposite = Shader.Find ("Hidden/uSkyLightShaftsComposite");
			m_LightShaftsMaterial = new Material (m_LightShaftsComposite);
			m_LightShaftsMaterial.hideFlags = HideFlags.HideAndDontSave;

			cam = GetComponent<Camera> ();
		}

		protected void OnDestroy ()
		{
			if (m_LightShaftsMaterial) {
				DestroyImmediate (m_LightShaftsMaterial);
			}
		}
			
		protected void Start ()
		{
			isSupported = CheckSupport ();
			LightShaftsTransform = m_Sun.transform;
			DownsampledViewSize ();
		}

		void DownsampledViewSize ()
		{
			if (resolution == LightShaftsResolution.Normal)
				DownsampleFactor = 2;
			else if (resolution == LightShaftsResolution.High)
				DownsampleFactor = 1;
			else
				DownsampleFactor = 4;
		}

		void OnRenderImage (RenderTexture source, RenderTexture destination)
		{
			if (!isSupported || cam == null || m_Sun == null){ 
				Graphics.Blit (source, destination);
				return;
			}

			cam.depthTextureMode |= DepthTextureMode.Depth; // should be using depth mode by default 
	            
			Vector3 origin = new Vector3 (0.5f, 0.5f, 0.0f);// shaft position on the screen;
			if (LightShaftsTransform)
				origin = cam.WorldToViewportPoint (this.transform.position - LightShaftsTransform.forward); // directional light
			else if (!LightShaftsTransform)
				origin = new Vector3 (0.5f, 0.5f, 0.0f); 
			
			int DownsampledViewSizeX = source.width / DownsampleFactor;
			int DownsampledViewSizeY = source.height / DownsampleFactor;
			
			RenderTexture tempBuffer0 = null;
			RenderTexture tempBuffer1 = RenderTexture.GetTemporary (DownsampledViewSizeX, DownsampledViewSizeY, 0);

			float horizionFade = Mathf.Clamp01 ((-LightShaftsTransform.forward.y + 0.02f) * Mathf.PI * 4);
			// only active the blur drawcall if shafts origin is in front of the camera
			m_LightShaftsMaterial.SetVector ("_BloomTintAndThreshold", new Vector4 (BloomTint.r, BloomTint.g, BloomTint.b, BloomThreshold));
			m_LightShaftsMaterial.SetVector ("_LightShaftParameters", new Vector4 (
											OcclusionDepthRange, 				// x	InvOcclusionDepthRange = cam.farClipPlane / OcclusionDepthRange
											BloomScale, 						// y
											horizionFade,						// z	
											OcclusionMaskDarkness)				// w
										);
			if (origin.z <= 0f) 
				m_LightShaftsMaterial.SetVector ("_LightShaftParameters", new Vector4 (0, 0, 0, 1f));
			
			
			m_LightShaftsMaterial.SetVector ("_TextureSpaceBlurOrigin", new Vector4 (origin.x, origin.y, 0f, 5f / BloomRadius));
	//		lightShaftsMaterial.SetFloat ("_NoSkyBoxMask", 1.0f - useSkyBoxAlpha);

			// Downsample:-----------------------------------------------------------------------------

			Graphics.Blit (source, tempBuffer1, m_LightShaftsMaterial, 2);
			

			// Radial blur:-----------------------------------------------------------------------------

			Vector2 BlurScaleDelta = new Vector2 (2f, 4f);
			Vector2 BlurOffsetDelta = new Vector2 (0f, 1f);
			int BlurPassDelta = 1; // if only 1 iteration then change it to pass 6
			
			for (int i = 0; i < 2; i++) {
				// each iteration takes 2 * 4 samples 
				Vector2 BlurScale = BlurScaleDelta;
				Vector2 BlurOffset = BlurOffsetDelta;
				
				tempBuffer0 = RenderTexture.GetTemporary (DownsampledViewSizeX, DownsampledViewSizeY, 0); 
				m_LightShaftsMaterial.SetVector ("_LightShaftBlurParameters", new Vector4 (BlurScale.x, BlurOffset.x, 0f, 0f));
				Graphics.Blit (tempBuffer1, tempBuffer0, m_LightShaftsMaterial, 1);
				RenderTexture.ReleaseTemporary (tempBuffer1);

				tempBuffer1 = RenderTexture.GetTemporary (DownsampledViewSizeX, DownsampledViewSizeY, 0);
				m_LightShaftsMaterial.SetVector ("_LightShaftBlurParameters", new Vector4 (BlurScale.y, BlurOffset.y, 0f, 0f));
				int BlurPass = BlurPassDelta;
				Graphics.Blit (tempBuffer0, tempBuffer1, m_LightShaftsMaterial, BlurPass);
				RenderTexture.ReleaseTemporary (tempBuffer0);
				
				BlurScaleDelta += new Vector2 (BlurScaleDelta.x, BlurScaleDelta.y) * 2f;	
				BlurOffsetDelta += new Vector2 (BlurOffsetDelta.x, BlurOffsetDelta.y);
				BlurPassDelta = 6; // switch to pass #6 allows the tail of an occluder blend out smoothly
			}	
			m_LightShaftsMaterial.SetTexture ("_ApplySourceTexture", tempBuffer1);

			
			// Apply:---------------------------------------------------------------------------------	
			
			Graphics.Blit (source, destination, m_LightShaftsMaterial,
				(DebugMode == DebugViewMode.None) ? 0 :
				(DebugMode == DebugViewMode.ShaftMask) ? 3 :
				(DebugMode == DebugViewMode.OcclusionMask) ? 4 : 5);
			
			RenderTexture.ReleaseTemporary (tempBuffer1);	

		}

		public void OnValidate() 
		{
			OcclusionDepthRange = Mathf.Max( OcclusionDepthRange, 0f);
			DownsampledViewSize ();
		}
	}
}