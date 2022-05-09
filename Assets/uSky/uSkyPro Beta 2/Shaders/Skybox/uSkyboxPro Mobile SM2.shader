// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// --------------------------------------------------------------------
// This shader designed for Moblie platform or Fallback shader (SM 2.0)
// --------------------------------------------------------------------
// LIMITATION :
//
// Supports only Altitude Sample X1 
// No calculation of camera position 
// No Altitude Scale
// Always at ground/sea level camera view from the sky
// Always disabled skybox ocean effect
// No earth shadow
// No Moon Corona
//
// Ported Unity Photographic tonemapping formula for skybox :
// * Sky color has been saturated then original color
// ---------------------------------------------------------

 
Shader "uSkyPro/uSkyboxPro_Mobile" 
{
	Properties {
		[NoScaleOffset]		_MoonSampler ("Moon",2D) = "black" {}
		[NoScaleOffset]		_OuterSpaceCube("Outer Space Cubemap", Cube) = "black" {}
		[HideInInspector]	_turbidity ("Turbidity factor", Range (1,10)) = 1 // temp hide
	}
	SubShader 
	{
	Pass{	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox"}
			ZWrite Off Cull Off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "../Atmosphere.cginc"
			
			#pragma multi_compile __ USKY_HDR_MODE
			#pragma multi_compile __ USKY_SUNDISK
			#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
			
			#if defined(UNITY_COLORSPACE_GAMMA)
				#define LDR_OUTPUT(color) color
				#define HDR_OUTPUT(color) pow(color* 1.265, 0.735)
			#else
				#define LDR_OUTPUT(color) color*color
				#define HDR_OUTPUT(color) color* 0.6129
			#endif
		
			sampler2D	_MoonSampler;
			samplerCUBE	_OuterSpaceCube;
			float4		_NightZenithColor, _NightHorizonColor, _MoonDirSize;
			float4x4	_SpaceRotationMatrix;
			float		_turbidity;
			
			// Enabled this to render the same sun disk as uSkyboxPro material
			// Disable it (Comment out) to render cheaper sun disk
			#define USKY_SUNDISK_HQ
			
			struct v2f 
			{
    			float4	pos				: SV_POSITION;
    			float3	worldPos		: TEXCOORD0;
    			float2	Mu_uMuS			: TEXCOORD1;
    			half3	MiePhase_g		: TEXCOORD2;
    			half2	NightGradient	: TEXCOORD3;
    			half3	NightSkyColor	: TEXCOORD4;
    			half2	moonTC			: TEXCOORD5;
    			half3	spaceTC			: TEXCOORD6;
    			half3	sunParams		: TEXCOORD7;    			
			};
						
			v2f vert(appdata_base v)
			{
    			v2f OUT;
    		#if UNITY_VERSION >= 540
				OUT.pos = UnityObjectToClipPos(v.vertex);
			#else
				OUT.pos = UnityObjectToClipPos(v.vertex);
			#endif
    			OUT.worldPos = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
    			
    			// Not physically based formula, just an approximation
    			float zenithAngle = atan2(normalize(OUT.worldPos).y, 0.5) * 1.3;

    			// approximation of optical depth
    			float opticalDepth = zenithAngle * (UNITY_PI / _turbidity) + _uSkyGroundOffset / 2e4;
    			OUT.Mu_uMuS.x = max(0.08, opticalDepth); // 0.08 to fix the ground rendering issue for mobile build

   				float uMuS = Get_uMuS (_SunDirSize.y);
   				// read the single third table only from right side of the precomputed inscatter texture
   				// no earth shadow
				OUT.Mu_uMuS.y = (uMuS + float(RES_NU) - 3) / float(RES_NU) ; 
				
    			// horizontal night sky gradient
    			float gr = saturate(opticalDepth * (0.1 / _NightHorizonColor.w));
    			gr *= 2 - gr;
    			OUT.NightGradient.x = gr * _uSkyNightParams.y;
    			OUT.NightGradient.y = max(1e-3, 1 - gr);
    			
    			OUT.NightSkyColor = lerp(_NightHorizonColor.xyz, _NightZenithColor.xyz, gr);
    			
    			// mie G term
				OUT.MiePhase_g = PhaseFunctionG(_uSkyMieG, _uSkyMieScale);// * sign(_LightColor0.w);
				
		#if USKY_SUNDISK
			#if defined(USKY_SUNDISK_HQ)
				float scale = 0.8 ;
				#if defined(UNITY_COLORSPACE_GAMMA)
					  scale = 0.4;
				#endif
				OUT.sunParams = PhaseFunctionG(.99 , _SunDirSize.w * scale * _uSkyExposure);
			#else	
				OUT.sunParams = float3(	0.9998 - _SunDirSize.w * 2e-4,								// X = smoothness
										0.9999 - _SunDirSize.w * 1e-4,								// Y = sun size
				  						SUN_BRIGHTNESS * 4 * _uSkyExposure * sign(_LightColor0.w)); // Z = sun brightness
			#endif	  						
		#else
				OUT.sunParams = float3(0,0,0);
		#endif
			
    			// night sky
    			float3 right = normalize( cross( _MoonDirSize.xyz, float3( 0, 0, 1 )));
				float3 up = cross(_MoonDirSize.xyz, right ); 			
				OUT.moonTC.xy = float2( dot(right, v.vertex.xyz), dot( up, v.vertex.xyz) )*_MoonDirSize.w + 0.5;
				OUT.spaceTC = mul((float3x3)_SpaceRotationMatrix, v.vertex.xyz);
				
    			return OUT;
			}
			

			half4 frag(v2f IN) : SV_Target
			{
			    float3 skyDir = normalize(IN.worldPos);
			    float nu = dot (skyDir, _SunDirSize.xyz); // sun direction

				// Use medium precision
				half3 extinction = half3(1,1,1);
				// inScatter
			    half3 col = Texture2D_Mobile (skyDir.y, nu, IN.Mu_uMuS, IN.MiePhase_g, extinction);
				
//------------------------------------------------------------------------------------------------------
				// night sky
				col += IN.NightSkyColor;
				
				// optional night sky elements
				// add moon
				fixed4 moonAlbedo = tex2D (_MoonSampler, IN.moonTC.xy);
				half moonMask = moonAlbedo.a * _uSkyNightParams_Mediump.y;
				
				// add outer space and dithering
				fixed4 spaceAlbedo = texCUBE (_OuterSpaceCube, IN.spaceTC);
				spaceAlbedo *= _uSkyNightParams_Mediump.z * (1 - moonMask);
				
				col += (moonAlbedo.rgb + spaceAlbedo.rgb) * IN.NightGradient.x;
//------------------------------------------------------------------------------------------------------

			#ifndef USKY_HDR_MODE
				col = col * (_uSkyExposure_Mediump * 1.5);
				col = HDRtoLDR(col);
				col = LDR_OUTPUT(col);
			#else
				col = col * _uSkyExposure_Mediump;
				col = HDR_OUTPUT(col);
			#endif

				// add sun disk
		#if USKY_SUNDISK
			#if defined(USKY_SUNDISK_HQ)
				half sun = SunFunction(nu, IN.sunParams);
				if (skyDir.y > 0)
					col += (sun * sign(_LightColor0.w)) * extinction;
			#else
				// Using the step function is cheaper, but renders jaggy sun disk edge on most desktop monitor screen,
				// however it will look good and smooth in iOS retina screen. 
//				half sun = step(IN.sunParams.x, nu); 
				half sun = smoothstep(IN.sunParams.x, IN.sunParams.y, nu);
				if (skyDir.y > 0)
					col += (sun * IN.sunParams.z) * extinction;
			#endif
		#endif
				
				half alpha = lerp(1.0, moonMask + IN.NightGradient.y, _uSkyNightParams_Mediump.x);
																								
				return half4(col, alpha);	
				
			}
			ENDCG
    	}
	}
}