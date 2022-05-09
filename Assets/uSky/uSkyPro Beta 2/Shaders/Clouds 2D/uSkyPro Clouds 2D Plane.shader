// Clouds shader that originally designed for uSky version 1.X
// Now it adapted for uSkyPro

// This shader will work with Sprite Renderer too.

Shader "uSkyPro/Clouds 2D Plane" {
Properties {
	[Header(Lighting)]
	[Enum(Sky Color,0,Equator Color,1)] _AmbientSource ("Ambient Source", int) = 1
    _Attenuation ("Attenuation", Range(0,5)) = 0.6
    _StepSize ("Step size", Range(0.001,0.02)) = 0.004
    _AlphaSaturation("Alpha saturation", Range(1,10)) = 2.0
    _LightColorMultiplier ("Light Color multiplier", Range(0,10)) = 4
    _SkyColorMultiplier("Sky Color multiplier", Range(0,10)) = 1.5
	_Mask ("Clouds Density", Range (0,4)) = 1.0

    [Header(Texture)]
	_CloudSampler ("Clouds Texture (RG)", 2D) = "white" {}

}
SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }

		Blend  SrcAlpha OneMinusSrcAlpha
		Zwrite Off  Cull Off

Pass {
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		
		#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
		
		#if defined(UNITY_COLORSPACE_GAMMA)
			#define GAMMA_OUT(color) pow(color,0.454545)
		#else
			#define GAMMA_OUT(color) color
		#endif
				
		UNITY_DECLARE_TEX2D (_CloudSampler);
		float4 _CloudSampler_ST;
		

		// x = NightFade, y = MoonFade, z = OuterSpaceIntensity
		uniform float3	_uSkyNightParams;
		
		uniform float3	_SunDirSize, _MoonDirSize, _uSkyLightColor, _NightZenithColor;
		uniform float	_LightColorMultiplier, _SkyColorMultiplier;
		uniform half	_Attenuation, _StepSize, _AlphaSaturation, _Mask;
		uniform int		_AmbientSource;

		struct v2f {
		    float4	pos 		: SV_POSITION;
		    float2	baseTC		: TEXCOORD0;
		    float3	toSun		: TEXCOORD1;
		    half3	skyColor	: TEXCOORD2;
		    half3	lightColor	: TEXCOORD3;
		};

		v2f vert (appdata_tan v)
		{
		    v2f OUT;

		#if UNITY_VERSION >= 540
			OUT.pos = UnityObjectToClipPos(v.vertex);
		#else
			OUT.pos = UnityObjectToClipPos(v.vertex);
		#endif
			OUT.baseTC = v.texcoord;
			
			// switching between the sun and moon direction, avoids the poping issue between lights
			float3 lightDir = lerp (_SunDirSize.xyz, _MoonDirSize.xyz, saturate(_uSkyNightParams.y));
			float3 objectSpaceLightPos = mul((float3x3)unity_WorldToObject, lightDir).xyz;
			
			TANGENT_SPACE_ROTATION;
			OUT.toSun = mul(rotation, objectSpaceLightPos);
			
			// ambient
			float3 unityAmbient = (_AmbientSource == 0)? unity_AmbientSky.xyz : unity_AmbientEquator.xyz;
				
			// fix the night sky brightness
			float brightnessScale = max(max(Luminance(_NightZenithColor.rgb)*4,_uSkyNightParams.z), 1.0 - _uSkyNightParams.x);

			// Shade Color
			OUT.skyColor = unityAmbient * (GAMMA_OUT(_SkyColorMultiplier) * brightnessScale);
			OUT.lightColor = max(_uSkyLightColor.xyz * _LightColorMultiplier, OUT.skyColor);
		
		#if defined(UNITY_COLORSPACE_GAMMA)
			OUT.lightColor = sqrt(OUT.lightColor);
		#endif
					
		    return OUT;
		}

		half4 frag (v2f IN) : SV_Target
		{
			const int c_numSamples = 8;
			
			// uv
			half3 toSun = normalize( IN.toSun.xyz );
			float2 sampleDir = toSun.xy * _StepSize; 
			float2 uv = IN.baseTC.xy;
			
			// only use red channel as clouds density 
			half opacity = UNITY_SAMPLE_TEX2D( _CloudSampler, uv ).r;
			opacity = min(opacity * _Mask, 1.0); 
			// Increase the "Alpha Opacity" during the night time to mask out background moon and stars
			opacity = lerp(opacity, min(opacity * 1.15, 1.0), _uSkyNightParams.x); 

			half density = 0.0;
			
			UNITY_FLATTEN
			if (opacity > 0.01) // bypass sampling any transparent pixels
			{
				for( int i = 0; i < c_numSamples; i++ )
				{
					float2 sampleUV = uv + i * sampleDir;
					half t = UNITY_SAMPLE_TEX2D( _CloudSampler, sampleUV ).r ;
					density += t ;
				}
			}

			half c = exp2( -_Attenuation * density);
			half a = pow( opacity, _AlphaSaturation );
			half3 col = lerp( IN.skyColor, IN.lightColor, c );
			
			return half4( col, a ) ;
			
		}
		ENDCG

    }
}
Fallback Off
} 