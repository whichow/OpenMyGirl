Shader "Hidden/uSkyPro/Precompute" { 
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
}

SubShader { 
			Tags { "PreviewType"="Plane" }
	// Transmittance
	Pass { 
			CGPROGRAM
			#include "AtmospherePrecompute.cginc"
			#pragma target 3.0
			#pragma vertex MainVS
			#pragma fragment TransmittancePS
			ENDCG
		}
		
	// Inscatter1T
	Pass { 
			CGPROGRAM
			#include "AtmospherePrecompute.cginc"
			#pragma target 3.0
			#pragma vertex MainVS
			#pragma fragment Inscatter1PS
			ENDCG
		}
	}
//-----------------------------------------------------------------------------------------------------	
	// TODO:
	// Try to do the Fallback to Shader Model 2.0. 
	// Too many instruction for d3d9 or d3d11_9x to fit in SM2, If excluded those platform in compiler 
	// that at least this is something good for WebGl or Mobile build, maybe?
	//
	// If we switch the Graphics Emulation to Shader Model 2 in Edior,
	// and editor does not support RenderTextureFormat.ARGBHalf, it seems only working in ARGBFloat.
/*
SubShader { 
			Tags { "PreviewType"="Plane" }
	// Transmittance
	Pass { 
			CGPROGRAM
			#include "AtmospherePrecompute.cginc"
			#pragma vertex MainVS
			#pragma fragment TransmittancePS
			
			#pragma exclude_renderers d3d9 d3d11_9x
//			#pragma only_renderers glcore opengl gles metal
			 
			ENDCG
		}
		
	// Inscatter1T
	Pass { 
			CGPROGRAM
			#include "AtmospherePrecompute.cginc"
			#pragma vertex MainVS
			#pragma fragment Inscatter1PS
			
			#pragma exclude_renderers d3d9 d3d11_9x
//			#pragma only_renderers glcore opengl gles metal
			
			ENDCG
		}
		
	}
*/
}