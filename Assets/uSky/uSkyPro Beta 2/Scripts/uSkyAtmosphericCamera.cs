using UnityEngine;

namespace usky
{
	/// <summary>
	/// This is the main camera image effect for atmospheric scattering.
	/// This script needs to be attached to a Main Camera GameObject.
	/// </summary>

/*	New feature in Unity 5.4
 *	This will copy the Image effect from the main camera onto the Scene View camera. 
 *	This can be enabled / disabled in the Scene View effects menu. */
#if UNITY_5_4_OR_NEWER
	[ImageEffectAllowedInSceneView]
#endif

	[ExecuteInEditMode][DisallowMultipleComponent]
	[RequireComponent (typeof(Camera))]
	[AddComponentMenu ("uSkyPro/uSky Atmospheric Camera")]
	public class uSkyAtmosphericCamera : MonoBehaviour
	{
		[HideInInspector] public Shader m_AtmosphericCameraShader;
		private Material m_AtmosphericCameraMaterial;
		private Camera cam;
		private bool shouldRender = true;

		uSkyAtmosphericScattering AtmoScatter { get { return  uSkyAtmosphericScattering.instance; } }

		protected bool CheckSupport ()
		{
			// support ImageEffects and support depth?
			if (!SystemInfo.supportsImageEffects || !SystemInfo.SupportsRenderTextureFormat (RenderTextureFormat.Depth)) {
				return false;
			} else
				return true;
		}

		void CheckMaterial ()
		{
			// Atmospheric scattering material and shader
			if (m_AtmosphericCameraShader == null)
				m_AtmosphericCameraShader = Shader.Find ("Hidden/uSkyPro/AtmosphericScatteringCamera");

			if (m_AtmosphericCameraMaterial == null || m_AtmosphericCameraMaterial.shader != m_AtmosphericCameraShader) {
				m_AtmosphericCameraMaterial = new Material (m_AtmosphericCameraShader);
				m_AtmosphericCameraMaterial.hideFlags = HideFlags.DontSave;
				m_AtmosphericCameraMaterial.SetFloat ("_uSkySkyboxOcean", 0);
			}
		}

		void OnEnable ()
		{
			CheckMaterial ();
			cam = GetComponent<Camera> ();
		}

		void Start ()
		{
			shouldRender = CheckSupport () && ((cam && uSkyPro.instance));
		}

		[ImageEffectOpaque]
		void OnRenderImage (RenderTexture source, RenderTexture destination)
		{	
			if (!shouldRender || (!AtmoScatter || !AtmoScatter.EnableScattering)) { 
				Graphics.Blit (source, destination);
				return;
			}

			cam.depthTextureMode |= DepthTextureMode.Depth; // needed this?


			int pass = (AtmoScatter.OcclusionDebug && AtmoScatter.UseOcclusion) ? 1 : 0;

			FrustumCornersGraphicsBlit (source, destination, m_AtmosphericCameraMaterial, pass);

		}

		static void FrustumCornersGraphicsBlit (RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
		{
			RenderTexture.active = dest;
			       
			fxMaterial.SetTexture ("_MainTex", source);	        
		        	        
			GL.PushMatrix ();
			GL.LoadOrtho ();
		    	
			fxMaterial.SetPass (passNr);	
			
			GL.Begin (GL.QUADS);

			GL.MultiTexCoord2 (0, 0.0f, 0.0f); 
			GL.Vertex3 (0.0f, 0.0f, 3.0f); // BL
			
			GL.MultiTexCoord2 (0, 1.0f, 0.0f); 
			GL.Vertex3 (1.0f, 0.0f, 2.0f); // BR
			
			GL.MultiTexCoord2 (0, 1.0f, 1.0f); 
			GL.Vertex3 (1.0f, 1.0f, 1.0f); // TR
			
			GL.MultiTexCoord2 (0, 0.0f, 1.0f); 
			GL.Vertex3 (0.0f, 1.0f, 0.0f); // TL
			
			GL.End ();
			GL.PopMatrix ();
			
		}
	}
}