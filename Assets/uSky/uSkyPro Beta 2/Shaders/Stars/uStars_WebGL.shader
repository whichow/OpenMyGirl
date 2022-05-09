// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// fix the stars shader issue for WebGL and Android build
// Replaced the array variable with "if" statment
Shader "Hidden/uSkyPro/uStars_WebGL" {

	CGINCLUDE
	#include "UnityCG.cginc"
							
	#if defined(UNITY_COLORSPACE_GAMMA)
		#define OUTPUT(color) color
	#else
		#define OUTPUT(color) (color*color)*2
	#endif
		
	uniform float		_StarIntensity;
	uniform float4x4	_StarRotationMatrix;
	
	struct appdata_t {
		float4 vertex		: POSITION;
		float4 ColorAndMag	: COLOR;
		float2 texcoord		: TEXCOORD;
	};
	
	struct v2f 
	{
		float4 pos	: SV_POSITION;
		half4 Color	: COLOR;
		half2 uv	: TEXCOORD0;
	};	
	
	float GetFlickerAmount(in float2 pos)
	{
		float2 hash = frac(pos.xy * 256);
		float index = frac(hash.x + (hash.y + 1) * (_Time.x * 2 + unity_DeltaTime.z)); // flickering speed
		index *= 4;

		float f = frac(index)* 2.5;
		int i = (int)index;

		float2 tab =(i == 1)?	float2(0.897907815,-0.347608525):
					(i == 2)?	float2(0.550299290, 0.273586675):
					(i == 3)?	float2(0.823885965, 0.098853070):
								float2(0.922739035,-0.122108860);
								
		return  tab.x + f * tab.y ;
	}	
	
	v2f vert(appdata_t v)
	{
		v2f OUT = (v2f)0;

		float3 t = mul((float3x3)_StarRotationMatrix, v.vertex.xyz) + _WorldSpaceCameraPos.xyz; 
	#if UNITY_VERSION >= 540
		OUT.pos = UnityObjectToClipPos(t);
	#else
		OUT.pos = UnityObjectToClipPos(float4(t,1));
	#endif

		float appMag = 6.5 + v.ColorAndMag.w * (-1.44 -1.5);
		float brightness = GetFlickerAmount(v.vertex.xy) * pow(5.0, (-appMag -1.44)/ 2.5);
		
		OUT.Color = _StarIntensity * float4( brightness * v.ColorAndMag.xyz, brightness );
		OUT.uv = 6.5 * v.texcoord.xy - 6.5 * float2(0.5, 0.5);
		
		return OUT;
	}

	half4 frag(v2f IN) : SV_Target
	{
		half2 distCenter = IN.uv.xy;
		half scale = exp(-dot(distCenter, distCenter));
		half3 col = IN.Color.xyz * scale + 5 * IN.Color.w * pow(scale, 10);
		col = OUTPUT(col);
		return half4(col, 0);
	}
	ENDCG
//----------------------------------------------
SubShader {
	Tags { "Queue"="Geometry+502" "IgnoreProjector"="True" "RenderType"="Background" }
	
	Blend OneMinusDstAlpha  OneMinusSrcAlpha	// alpha 0
//	Blend OneMinusDstAlpha  SrcAlpha			// alpha 1

	ZWrite Off

Pass{	
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma multi_compile __ UNITY_COLORSPACE_GAMMA
	ENDCG
  }
 }
}
