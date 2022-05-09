using UnityEngine;
using usky.Internal;

namespace usky
{
	[ExecuteInEditMode]
	[AddComponentMenu("uSkyPro/uSky Clouds 2D")]
	public class uSkyClouds2D : MonoBehaviour 
	{
		public Material Clouds2DMaterial;
		public int cloudsLayer = 0;

		private Mesh m_SkyDome;

		void InitSkyDomeMesh ()
		{
			uSkyDomeData uSD = new uSkyDomeData ();

			// Read the baked mesh data from "uSkyDomeData.cs"
			m_SkyDome			= new Mesh();
			m_SkyDome.name		= "Generated uSkyDome";
			m_SkyDome.vertices	= uSD.vertices;
			m_SkyDome.triangles = uSD.triangles;
			m_SkyDome.uv		= uSD.UV0;
			m_SkyDome.uv2		= uSD.UV2;
			m_SkyDome.normals	= uSD.normals;
			m_SkyDome.tangents	= uSD.tangents;
			m_SkyDome.bounds	= new Bounds (Vector3.zero, Vector3.one * 2e9f);
			m_SkyDome.hideFlags	= HideFlags.DontSave;
		}

		void Awake ()
		{
			if (m_SkyDome == null) 
				InitSkyDomeMesh ();
		}

//		void OnEnable ()
//		{
//			uSkyInternal.SetCloudsReflectionProbeState (Clouds2DMaterial);
//		}

		void OnDestroy() 
		{
			if (m_SkyDome) 
				DestroyImmediate(m_SkyDome);
		}

		void Update ()
		{
			if (m_SkyDome == null || Clouds2DMaterial == null)
				return;

			Graphics.DrawMesh (m_SkyDome, Vector3.zero, Quaternion.identity, Clouds2DMaterial, cloudsLayer);

			// Too much cpu overhead for runtime backwards checking for clouds material dirtiness.
			// Disabled for now, It will only do realtime probe update in editor via ShaderGUI script. 
//			uSkyInternal.SetCloudsReflectionProbeState (Clouds2DMaterial); 

		}

		void OnValidate () 
		{
			cloudsLayer = Mathf.Clamp (cloudsLayer, 0, 31);
		}

	}
}