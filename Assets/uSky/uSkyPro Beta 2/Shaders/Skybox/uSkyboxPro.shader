// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "uSkyPro/uSkyboxPro" 
{
	Properties 
	{
		[NoScaleOffset]		_MoonSampler ("Moon",2D) = "black" {}
		[NoScaleOffset]		_OuterSpaceCube("Outer Space Cubemap", Cube) = "black" {}
//							_turbidity ("Turbidity factor", Range (1,10)) = 1
		[HideInInspector]	_uSkySkyboxOcean ("Skybox Ocean", int) = 0
	}
	
	SubShader 
	{
		Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox"}
		Cull Off ZWrite Off 
	
    	Pass 
    	{	
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "../Atmosphere.cginc"
			
			#pragma multi_compile __ USKY_MULTISAMPLE
			#pragma multi_compile __ USKY_HDR_MODE
			#pragma multi_compile __ USKY_SUNDISK
			#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
			
			#if defined(UNITY_COLORSPACE_GAMMA)
				#define COLOR_2_LINEAR(color) color*(0.4672*color+0.266)
				#define GAMMA_2_OUTPUT(color) color
				#define HDR_OUTPUT(color)  pow(color* 1.265, 0.735)
			#else
				#define COLOR_2_LINEAR(color) color*color
				#define GAMMA_2_OUTPUT(color) color*color
				#define HDR_OUTPUT(color) color* 0.6129
			#endif
			
			sampler2D	_MoonSampler;
			samplerCUBE	_OuterSpaceCube;
//			float4 		_uSkyGroundColor;
			float4		_NightZenithColor,_NightHorizonColor, _MoonInnerCorona, _MoonOuterCorona;
			float4		_MoonDirSize;
			float4x4	_SpaceRotationMatrix;
//			float		_turbidity;

						
			struct v2f 
			{
    			float4  pos						: SV_POSITION;
    			float4	worldPosAndCamHeight	: TEXCOORD0;
    			float3	MiePhase_g				: TEXCOORD1;
    			float3	Sun_g					: TEXCOORD2;
    			float2	moonTC					: TEXCOORD3;
				float3	spaceTC					: TEXCOORD4;
//				float2	uv 						: TEXCOORD5; // debug
			};

			v2f vert(appdata_base v)
			{
    			v2f OUT;
    		#if UNITY_VERSION >= 540
				OUT.pos = UnityObjectToClipPos(v.vertex);
			#else
				OUT.pos = UnityObjectToClipPos(v.vertex);
			#endif
    			OUT.worldPosAndCamHeight.xyz = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);

    			// if the camera height is outside atmospheric precomputed buffer range, it will occur rendering artifacts
    			OUT.worldPosAndCamHeight.w = max(_WorldSpaceCameraPos.y*_uSkyAltitudeScale + _uSkyGroundOffset, 0.0);// no lower than sealevel
//    			OUT.worldPosAndCamY.xyz = lerp(float3(0,0,0), OUT.worldPos, 1/_turbidity ); // no affect

//    			OUT.uv = v.texcoord.xy;// debug
				OUT.MiePhase_g = PhaseFunctionG(_uSkyMieG,_uSkyMieScale);
				
			#if USKY_SUNDISK
				float scale = 8e-3 ;
				#if defined(UNITY_COLORSPACE_GAMMA)
					  scale = 4e-3 ;
				#endif
				OUT.Sun_g = PhaseFunctionG(.99 , _SunDirSize.w * scale * _uSkyExposure);
			#else
				OUT.Sun_g = float3(0,0,0);
			#endif
			
    			// night sky
    			float3 right = normalize( cross( _MoonDirSize.xyz, float3( 0, 0, 1 )));
				float3 up = cross( _MoonDirSize.xyz, right ); 			
				OUT.moonTC = float2( dot( right, v.vertex.xyz), dot( up, v.vertex.xyz) )*_MoonDirSize.w + 0.5;
				OUT.spaceTC = mul((float3x3)_SpaceRotationMatrix, v.vertex.xyz);
			
    			return OUT;
			}
			
			float4 frag(v2f IN) : SV_Target
			{
			    float3 dir = normalize(IN.worldPosAndCamHeight.xyz);
			    float3 camera = float3(0.0, IN.worldPosAndCamHeight.w, 0.0);
			    float nu = dot( dir, _SunDirSize.xyz); // sun direction
			    				
				float3 extinction;
				// inscatter
				float3 col = SkyRadiance(camera, dir, nu, IN.MiePhase_g, extinction) ; 
//----------------------------------------------------------------------------------				
				// night sky
				float3 nightSkyColor = float3(0,0,0);
				float moonMask = 0.0;
				float gr = 1.0;
//			if ( _SunDirSize.y < 0.25 )
			{				
				// add horizontal night sky gradient
				gr = saturate(extinction.z * .25 / _NightHorizonColor.w );
				gr *= 2 - gr;

				nightSkyColor = lerp(_NightHorizonColor.xyz, _NightZenithColor.xyz, gr);
				// add moon and outer space
				float4 moonAlbedo = tex2D ( _MoonSampler, IN.moonTC.xy );
				moonMask = moonAlbedo.a * _uSkyNightParams.y;
				
				float4 spaceAlbedo = texCUBE (_OuterSpaceCube, IN.spaceTC);		
				nightSkyColor += ( moonAlbedo.rgb * _uSkyNightParams.y + spaceAlbedo.rgb * (max(1-moonMask,gr) * _uSkyNightParams.z)) * gr ;

				// moon corona
				float m = 1 - dot( dir, _MoonDirSize.xyz);
				nightSkyColor += _MoonInnerCorona.xyz * (1.0 / (1.05 + m * _MoonInnerCorona.w));
				nightSkyColor += _MoonOuterCorona.xyz * (1.0 / (1.05 + m * _MoonOuterCorona.w));
			}
//----------------------------------------------------------------------------------				
			#ifndef USKY_HDR_MODE
				col += nightSkyColor;
				col = GAMMA_2_OUTPUT(hdr2(col*_uSkyExposure));
//				col = GAMMA_2_OUTPUT(HDRtoRGB(col*_uSkyExposure*1.5));
			#else
				col += COLOR_2_LINEAR(nightSkyColor);// TODO : not accurate
				col = HDR_OUTPUT(col*_uSkyExposure);
			#endif

				// add sun disc
			#if USKY_SUNDISK
				float sun = SunFunction(nu, IN.Sun_g);
				col += (sun * sign(_LightColor0.w)) * extinction;
			#endif
				
				float alpha = lerp( 1.0, max(1e-3, moonMask+(1-gr)), _uSkyNightParams.x);
				
				return float4(col, alpha);
			}			
			ENDCG
    	}
	}
	Fallback "uSkyPro/uSkyboxPro_Mobile"

}