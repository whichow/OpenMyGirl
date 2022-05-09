Shader "Hidden/uSkyLightShaftsComposite" {
	Properties {
		_MainTex ("Base", 2D) = "white" {}
		_ApplySourceTexture ("Color", 2D) = "white" {}
	}
	
	CGINCLUDE
				
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos	: POSITION;
		float2 uv	: TEXCOORD0;
		#if UNITY_UV_STARTS_AT_TOP
		float2 uv1	: TEXCOORD1;
		#endif
		float2 origin : TEXCOORD2;		
	};
		
	sampler2D		_MainTex;
	sampler2D		_ApplySourceTexture;
	sampler2D		_CameraDepthTexture;
	uniform float	_NoSkyBoxMask;
	uniform float4	_MainTex_TexelSize;	
	uniform float4	_MainTex_ST;
	
//-------------------------------------------------------------------------------------------------
//  Tint in rgb, threshold in a.  
	uniform float4 _BloomTintAndThreshold ;	

// Origin in texture coordinates in xy, BloomRadiusMask in w	
	uniform float4 _TextureSpaceBlurOrigin; 

// 1.0 / OcclusionDepthRange in x, BloomScale in y, horizionFade in z, OcclusionMaskDarkness in w
	uniform float4 _LightShaftParameters;
#define InvOcclusionDepthRange	_ProjectionParams.z /_LightShaftParameters.x
#define _BloomScale			_LightShaftParameters.y
#define _horizionFade		_LightShaftParameters.z
// X: BlurVectorScale, Y: BlurVectorOffset
	uniform float4 			_LightShaftBlurParameters;
#define _BlurVectorScale	_LightShaftBlurParameters.x
#define _BlurVectorOffset	_LightShaftBlurParameters.y

//	#define InvAspectRatio		float2(1.0,_ScreenParams.y/_ScreenParams.x)
	#define InvAspectRatio		float2(_ScreenParams.x/_ScreenParams.y, 1.0)
//-------------------------------------------------------------------------------------------------	

	v2f vert( appdata_img v ) {
		v2f o;
		float2 position = UnityObjectToClipPos(v.vertex).xy;
		o.pos = float4(position, 0.0,1.0);

		o.uv = UnityStereoTransformScreenSpaceTex(v.texcoord.xy);
		o.origin = v.texcoord.xy;

	#if UNITY_UV_STARTS_AT_TOP
		o.uv1 = o.uv;
		if (_MainTex_TexelSize.y < 0)
			o.uv1.y = 1-o.uv1.y;
	#endif				
		
		return o;
	}
		// Screen Mode
	float3  ScreenBlend(  float3  Color1,  float3  Color2 ){
		return 1.0 - (1.0 - Color1) * (1.0 - Color2);
	}
	
	float4 fragScreen(v2f i) : SV_Target { 
		float4 SceneColor = tex2D (_MainTex, i.uv.xy);
		#if UNITY_UV_STARTS_AT_TOP
		float2 InUV = i.uv1.xy;
		#else
		float2 InUV = i.uv.xy;
		#endif
	  	float4 LightShaftColorAndMask = tex2D (_ApplySourceTexture, InUV);
	  	
	// LightShaftParameters.w is OcclusionMaskDarkness, use that to control what an occlusion value of 0 maps to
	// Lerp an occlusion value of 1 to a multiplier greater than one to balance out the brightness of the scene
		float  SceneColorMultiplier =  lerp(_LightShaftParameters.w, 1.5 - .5 * _LightShaftParameters.w, LightShaftColorAndMask.w * LightShaftColorAndMask.w);
	// Setup a mask based on where the blur origin is
		float  BlurOriginDistanceMask =  saturate(length((_TextureSpaceBlurOrigin.xy - i.origin)) *InvAspectRatio * 0.5) ; // 0.5 : higher value means faster fade out
	// Fade out occlusion over distance away from the blur origin
		SceneColorMultiplier = lerp(SceneColorMultiplier, 1.0, BlurOriginDistanceMask);

		float3 LightShaftColor = LightShaftColorAndMask.rgb * _BloomTintAndThreshold.rgb;

	// Use a screen blend to apply bloom to scene color, darken scene color by the occlusion factor
		float4 outColor =  float4 ( ScreenBlend ( LightShaftColor, saturate(SceneColor.rgb * SceneColorMultiplier)), 1.0);

		return outColor;
	}
//-------------------------------------------------------------------------------------------------	
	float4 fragShaftMask(v2f i) : SV_Target { 
		#if UNITY_UV_STARTS_AT_TOP
		float4 colorB = tex2D (_ApplySourceTexture, i.uv1.xy);
		#else
		float4 colorB = tex2D (_ApplySourceTexture, i.uv.xy);
		#endif
		return colorB * _BloomTintAndThreshold; // Shaft Mask from downsample pass
	}
	
	float4 fragOcclusionMask(v2f i) : SV_Target { 
		#if UNITY_UV_STARTS_AT_TOP
		float2 InUV = i.uv1.xy;
		#else
		float2 InUV = i.uv.xy;
		#endif	 
		float4 colorB = tex2D (_ApplySourceTexture, InUV);
	// Setup a mask based on where the blur origin is
		float  BlurOriginDistanceMask =  saturate(length(_TextureSpaceBlurOrigin.xy - i.origin) * 0.5) ;
	// Fade out occlusion over distance away from the blur origin
		colorB.a = lerp(colorB.a, .8, BlurOriginDistanceMask);
	  	colorB.a = lerp(colorB.a, .8, _LightShaftParameters.w);
		return float4(colorB.aaa,0.0); // Only show Occlusion Mask after blur pass
	}
	
	float4 fragOccDepth(v2f i) : SV_Target { 
		#if UNITY_UV_STARTS_AT_TOP
		float depthSample = UNITY_SAMPLE_DEPTH(tex2D (_CameraDepthTexture, i.uv1.xy));
		#else
		float depthSample = UNITY_SAMPLE_DEPTH(tex2D (_CameraDepthTexture, i.uv.xy));		
		#endif
		depthSample = Linear01Depth (depthSample);
		return float4(depthSample.rrr * InvOcclusionDepthRange,0.0); // Only show Occlusion Mask that taken from Depth pass
	}
//-------------------------------------------------------------------------------------------------
	// optimized radial blur in 4 samples
	struct v2f_radial {
		float4 pos : POSITION;
		float2 uv0 : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
		float2 uv2 : TEXCOORD2;
		float2 uv3 : TEXCOORD3;
//		float2 uv4 : TEXCOORD4;
//		float2 uv5 : TEXCOORD5;
//		float2 uv6 : TEXCOORD6;
//		float2 uv7 : TEXCOORD7;
	};
	
	// radial blur : vert
	v2f_radial vert_radial( appdata_img v ) {
		v2f_radial o;
		o.pos = UnityObjectToClipPos(v.vertex);
		float2 BlurVector = (_TextureSpaceBlurOrigin.xy - v.texcoord.xy);
		BlurVector *= 1.0/16.0; 

		float2 SampleUVs = v.texcoord.xy + BlurVector * _BlurVectorOffset;
		float2 SampleUVsDelta = BlurVector * _BlurVectorScale / 4.0;

		o.uv0.xy	=  UnityStereoTransformScreenSpaceTex(v.texcoord.xy);// + 0.0 * SampleUVsDelta ;
		o.uv1.xy	=  UnityStereoTransformScreenSpaceTex(SampleUVs + 1.0 * SampleUVsDelta) ;
		o.uv2.xy 	=  UnityStereoTransformScreenSpaceTex(SampleUVs + 2.0 * SampleUVsDelta) ;
		o.uv3.xy 	=  UnityStereoTransformScreenSpaceTex(SampleUVs + 3.0 * SampleUVsDelta) ;
//		o.uv4.xy 	=  SampleUVs + 4.0 * SampleUVsDelta ;
//		o.uv5.xy 	=  SampleUVs + 5.0 * SampleUVsDelta ;
//		o.uv6.xy 	=  SampleUVs + 6.0 * SampleUVsDelta ;
//		o.uv7.xy 	=  SampleUVs + 7.0 * SampleUVsDelta ;

		return o; 
	}

	// radial blur : frag 
	half4 frag_radial(v2f_radial i) : SV_Target 
	{			
		half4 BlurredValues = half4(0,0,0,0);

		BlurredValues += tex2D(_MainTex, i.uv0.xy);
		BlurredValues += tex2D(_MainTex, i.uv1.xy);
		BlurredValues += tex2D(_MainTex, i.uv2.xy);
		BlurredValues += tex2D(_MainTex, i.uv3.xy);
//		BlurredValues += tex2D(_MainTex, i.uv4.xy);
//		BlurredValues += tex2D(_MainTex, i.uv5.xy);
//		BlurredValues += tex2D(_MainTex, i.uv6.xy);
//		BlurredValues += tex2D(_MainTex, i.uv7.xy);
		return BlurredValues / 4;

	}

	// rough approximated
	// ===================================================
	// 8 samples		6 sample		4 samples	
	//----------------------------------------------------
	//	2.0				2.0				2.0
	//	1.75			1.5				1.0	
	//	1.5				1.25			.75
	//	1.25			1				.25
	//	.75				.75
	//	.5				.25
	//	.25
	//	.125	
	// ===================================================
	// This extra multiply allows the tail of an occluder to blend out smoothly 
	half4 frag_radialBlend(v2f_radial i) : SV_Target 
	{	
		half4 BlurredValues = half4(0,0,0,0);
		BlurredValues += tex2D(_MainTex, i.uv0.xy)*2.0 ;
		BlurredValues += tex2D(_MainTex, i.uv1.xy); // *1
		BlurredValues += tex2D(_MainTex, i.uv2.xy)*.75;
		BlurredValues += tex2D(_MainTex, i.uv3.xy)*.25;
//		BlurredValues += tex2D(_MainTex, i.uv4.xy)*0.75;
//		BlurredValues += tex2D(_MainTex, i.uv5.xy)*0.5 ;
//		BlurredValues += tex2D(_MainTex, i.uv6.xy)*.25;
//		BlurredValues += tex2D(_MainTex, i.uv7.xy)*.125;
		return BlurredValues / 4;
	}	

//-------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------
	// Enable Depth Downsample
	float4 frag_depth (v2f i) : SV_Target {
		#if UNITY_UV_STARTS_AT_TOP
		float2 InUV = i.uv1.xy;
		#else
		float2 InUV = i.uv.xy;
		#endif
		float DownsampledSceneDepth = UNITY_SAMPLE_DEPTH(tex2D (_CameraDepthTexture, InUV));
		float4 DownsampledSceneColor = tex2D (_MainTex, InUV);
		DownsampledSceneDepth = Linear01Depth (DownsampledSceneDepth);
		
		// Setup a mask that is 1 at the edges of the screen and 0 at the center
		float EdgeMask = 1.0  - InUV.x * (1.0  - InUV.x) * InUV.y * (1.0  - InUV.y) * 8.0 ;

		// Non-Stereo uv
		// float2 originUV = i.origin;
		// float EdgeMask = 1.0  - originUV.x * (1.0 - originUV.x) * originUV.y * (1.0 - originUV.y) * 8.0 ;
		EdgeMask = EdgeMask * EdgeMask * EdgeMask * EdgeMask;
		
		float4 outColor = float4(0,0,0,0);

		// Only bloom colors over BloomThreshold
		float BloomLuminance = Luminance(DownsampledSceneColor.rgb);
		float AdjustedLuminance =  max(BloomLuminance - _BloomTintAndThreshold.a, 0.0); 
		float3 BloomColor = _BloomScale * DownsampledSceneColor.rgb / BloomLuminance * AdjustedLuminance * 2.0;

//		float skyboxAlpha = max( DownsampledSceneColor.a, (_NoSkyBoxMask * BloomLuminance));
		
		// Filter the occlusion mask instead of the depths
//		float InvOcclusionDepthRange = _LightShaftParameters.x; // predefined
		float OcclusionMask = DownsampledSceneDepth * InvOcclusionDepthRange;
		
		// Apply the edge mask to the occlusion factor
		float OcclusionAndEdgeMask = max(OcclusionMask, EdgeMask);
		outColor.a = min(OcclusionAndEdgeMask, 0.8); // .8 to balanced skybox brightness

		// Dim out when sun is close to horizion
		BloomColor *= _horizionFade;						// bloom
		outColor.a = lerp(.8, outColor.a, _horizionFade);	// occlusion

		// Only allow bloom from pixels whose depth are in the far float of OcclusionDepthRange
		float BloomDistanceMask = saturate((DownsampledSceneDepth - .5  / InvOcclusionDepthRange) * InvOcclusionDepthRange);
		// Setup a mask that is 0 at _TextureSpaceBlurOrigin and increases to 1 over distance
		float BlurOriginDistanceMask = 1.0 - saturate(length((_TextureSpaceBlurOrigin.xy - i.origin) * InvAspectRatio) * _TextureSpaceBlurOrigin.w);

		// Calculate bloom color with masks applied
		outColor.rgb =  BloomColor * BloomDistanceMask * (1.0 - EdgeMask) * BlurOriginDistanceMask * BlurOriginDistanceMask;// * skyboxAlpha;

		return outColor;
	}		

	ENDCG
//=================================================================================================
	
Subshader {
  // #0 : Apply Screen Mode
 Pass {
 	  Blend Off
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragScreen
      
      ENDCG
  }
  // # 1  radial blur
 Pass {
	  Blend One Zero
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert_radial
      #pragma fragment frag_radial
      ENDCG
  }
  // # 2  downsample (depth)
  Pass {
 	  Blend Off  	
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag_depth
      ENDCG
  }
   // # 3 Shaft Mask
  Pass {
 	  Blend Off
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragShaftMask
      ENDCG
  }
    // # 4 Occlusion Mask
  Pass {
 	  Blend Off
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragOcclusionMask
      ENDCG
  }
      // # 5 Occlusion Depth Range
  Pass {
 	  Blend Off
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment fragOccDepth
      ENDCG
  }
    // 6 : radial blur with tail blend out
 Pass {
	  Blend One Zero
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma vertex vert_radial
      #pragma fragment frag_radialBlend
      
      ENDCG
  }
}

Fallback off
	
} // shader