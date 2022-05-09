// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Clouds shader that originally designed for uSky version 1.X
// Now it adapted for uSkyPro

Shader "uSkyPro/Clouds 2D" {
Properties {
	[Header(Lighting)]
	[Enum(Sky Color,0,Equator Color,1)] _AmbientSource ("Ambient Source", int) = 1
    _Attenuation ("Attenuation", Range(0,5)) = 0.6
    _StepSize ("Step size", Range(0.001,0.02)) = 0.004
    _AlphaSaturation("Alpha saturation", Range(1,10)) = 2.0
    _LightColorMultiplier ("Light Color multiplier", Range(0,10)) = 4
    _SkyColorMultiplier("Sky Color multiplier", Range(0,10)) = 1.5
    _Mask ("Clouds density", Range (0,4)) = 1.0
    _ScatterMultiplier("Scatter multiplier", Range (0,10)) = 1.0
    	
    [Header(Texture)]
	[Enum(Rectangular,0,Polar,1)] _Mapping ("Mapping mode", int) = 0	
	_CloudSampler ("Clouds Texture (R)", 2D) = "white" {}
	
	[Header(Animation)]
	// Range 0 ~ 360 for non-animated Rotation
    _RotateSpeed("Rotate speed", Range (-1,1)) = 0.0
	[Header(Others)]
	_HeightOffset("Height Offset", float) = 0.0
    
}
SubShader {
		Tags { "Queue"="Geometry+501" "RenderType"="Background" }
//		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"  }
		
		Blend  SrcAlpha OneMinusSrcAlpha
		Zwrite Off  

Pass {
		Name "BASE"
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		#include "/../Atmosphere.cginc"
		
		#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
		
		#if defined(UNITY_COLORSPACE_GAMMA)
			#define GAMMA_OUT(color) pow(color,0.454545)
		#else
			#define GAMMA_OUT(color) color
		#endif

		UNITY_DECLARE_TEX2D (_CloudSampler);
		UNITY_DECLARE_TEX2D (_CurlSampler);
		float4 _CloudSampler_ST;


		uniform float3	_MoonDirSize, _uSkyLightColor, _NightZenithColor;
		uniform float	_RotateSpeed, _LightColorMultiplier, _SkyColorMultiplier;
		uniform half	_Attenuation, _StepSize, _AlphaSaturation, _Mask, _ScatterMultiplier;
		uniform int		_AmbientSource, _Mapping;
		uniform float	_HeightOffset;

		struct appdata_t {
			float4	vertex		: POSITION;
			float4	tangent		: TANGENT;
			float3	normal		: NORMAL;
    		float2  rectangular	: TEXCOORD0; // uv0
    		float2  polar		: TEXCOORD1; // uv2
		};
		
		struct v2f {
		    float4	pos 		: SV_POSITION;
		    float2	baseTC		: TEXCOORD0;
		    float2	toSun		: TEXCOORD1;
		    half3	skyColor	: TEXCOORD2;
		    half3	lightColor	: TEXCOORD3;
		    half3	worldPos	: TEXCOORD4;
		    half3	miePhase_g	: TEXCOORD5;
			half3	lightDir	: TEXCOORD6;
		};

		float3 RotateAroundYInDegrees (float3 vertex, float degrees)
		{
			float alpha = degrees * (UNITY_PI / 180.0);
			float sina, cosa;
			sincos(alpha, sina, cosa);
			float2x2 m = float2x2(cosa, -sina, sina, cosa);
			return float3(mul(m, vertex.xz), vertex.y).xzy;
		}

		v2f vert (appdata_t v)
		{
		    v2f OUT;
			float offsetValue = _RotateSpeed *_Time.y+ unity_DeltaTime.z;
		    float3 t = RotateAroundYInDegrees(v.vertex.xyz, offsetValue).xyz; //  animate rotation
		    // scale with camera’s far plane and following camera position.
			t = t * _ProjectionParams.z + _WorldSpaceCameraPos.xyz ; 
			t.y += _HeightOffset;
			
			OUT.pos = UnityObjectToClipPos(float4( t, v.vertex.w ));

		// #ifndef UNITY_REVERSED_Z 
		// 	OUT.pos.z = OUT.pos.w; // render behind all other objects on dx11, no affects on other platform
		// #endif
			// switching between the sun and moon direction, avoids the poping issue between lights
			float3 dir = lerp (_SunDirSize.xyz, _MoonDirSize.xyz, saturate(_uSkyNightParams.y ));

			// inverse rotation to correct the light direction from vertex animation
			dir = RotateAroundYInDegrees(dir, -offsetValue);
			OUT.lightDir = dir;

			TANGENT_SPACE_ROTATION;
			OUT.toSun = mul(rotation, dir).xy * _StepSize ;

			// uv mapping
			OUT.baseTC = ( _Mapping == 0 )? TRANSFORM_TEX (v.rectangular, _CloudSampler): v.polar ;
							
			// ambient source from Sky or Equator gradient color
			float3 unityAmbient = (_AmbientSource == 0)? unity_AmbientSky.xyz : unity_AmbientEquator.xyz;

			// fix the night sky brightness
			float brightnessScale = max(max(Luminance(_NightZenithColor.rgb)*4,_uSkyNightParams.z), 1.0 - _uSkyNightParams.x );

			// Shade Color
			OUT.skyColor = unityAmbient * (GAMMA_OUT(_SkyColorMultiplier) * brightnessScale);
			OUT.lightColor = max(_uSkyLightColor.xyz * _LightColorMultiplier, OUT.skyColor);
			
		#if defined(UNITY_COLORSPACE_GAMMA)
			OUT.lightColor = sqrt(OUT.lightColor);
		#endif

			OUT.worldPos.xyz = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);

			// scatter term (precomputed Mie-G term)
			float3 mie = _uSkyMieScale;
			mie.x *= GAMMA_OUT(_ScatterMultiplier);
			OUT.miePhase_g = PhaseFunctionG(_uSkyMieG, mie);

		    return OUT;
		}

		half4 frag (v2f IN) : SV_Target
		{
			const int c_numSamples = 8; //  keep in SM 2.0
			
			float3 dir = normalize(IN.worldPos.xyz);
			float nu = dot( dir, IN.lightDir.xyz);

			// uv
			float2 sampleDir = IN.toSun.xy ;
			float2 uv = IN.baseTC.xy;
			
			// only use red channel as clouds density 
			half opacity = UNITY_SAMPLE_TEX2D( _CloudSampler, uv ).r;
			// user define opacity level (need to clamp to 1 for HDR Camera)
			opacity = min(opacity * _Mask, 1.0); 
			// Increase the "Alpha Opacity" during the night time for better masking out the background moon and stars
			opacity = lerp(opacity, min(opacity * 1.15, 1.0), _uSkyNightParams.x); 

			half density = 0;
			
			UNITY_FLATTEN // prevent warning on dxd11 ? : gradient instruction used in a loop with varying iteration, forcing loop to unroll 
			if(opacity > 0.01) // bypass sampling any transparent pixels 
			{
				for( int i = 0; i < c_numSamples; i++ )
				{
					float2 sampleUV = uv + i * sampleDir;
					half t = UNITY_SAMPLE_TEX2D( _CloudSampler, sampleUV ).r ;
					density += t;
				}
			}

			// scatter term
			half phase = PhaseFunctionR()* _ScatterMultiplier ;
			half phaseM = PhaseFunctionM(nu, IN.miePhase_g);
			half scatter = (phase + phaseM) * (1.0 + nu * nu);

			half c = exp2( -_Attenuation * density + scatter);
			half a = pow( opacity, _AlphaSaturation );
			half3 col = lerp( IN.skyColor, IN.lightColor, c );
			
			return half4( col, a ) ;
			
		}
		ENDCG

    }
}
Fallback Off

// not really changed any shader UI, but it will check the material dirtiness for reflection probe update in editor
CustomEditor "uSkyClouds2DShaderGUI" 

} 