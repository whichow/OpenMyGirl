// Upgrade NOTE: commented out 'float4x4 _CameraToWorld', a built-in variable
// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

#ifndef USKY_POSTEFFECT
#define USKY_POSTEFFECT

sampler2D_float	_CameraDepthTexture;

//static const float PI			= 3.141592653589793;
//static const float Rad2Deg	= 360.0 / (PI * 2.0);
//static const float Deg2Rad	= (PI * 2.0) / 360.0;

// Unity Built-in shader variables
#define camNear		_ProjectionParams.y
#define camFar		_ProjectionParams.z
#define camTop		unity_CameraProjection._m11
#define camAspect	camTop / unity_CameraProjection._m00
#define tanFov		tan(atan(1.0 / camTop))


// Only needed to declare "float4x4 _CameraToWorld" before editor version 5.4
// 5.4 will automatically replaced this with "unity_CameraToWorld"
// float4x4 _CameraToWorld;
#define camRgt		unity_CameraToWorld._m00_m10_m20
#define camUp		unity_CameraToWorld._m01_m11_m21
#define camFwd		unity_CameraToWorld._m02_m12_m22

/*
inline float GetTanFov ()
{
	// https://developer.vuforia.com/forum/unity-3-extension-technical-discussion/vertical-fov-unity
	camFov = atan(1.0 / camTop); // Removed: "* 2.0 * Rad2Deg" code, simplified for next calculation  
	tanFov = tan(camFov); // simplfied version: eq. tan( Fov * 0.5 * Deg2Rad)
	return tanFov;
}


inline void GetCameraData ( out float3 camRgt, out float3 camUp, out float3 camFwd)
{
	// http://forum.unity3d.com/threads/get-main-camera-up-direction.189947/#post-1295774
	camRgt	= mul((float3x3)_CameraToWorld, float3(1,0,0));
	camUp	= mul((float3x3)_CameraToWorld, float3(0,1,0));
	camFwd	= mul((float3x3)_CameraToWorld, float3(0,0,1));
}
*/

// Based on Unity Image Effects GlobalFog.cs script
inline float4 FrustumCorners (int index)
{
	float camNearTanFov = camNear * tanFov;
	float3 toRight	= camRgt * camNearTanFov * camAspect;
	float3 toTop	= camUp * camNearTanFov;
	
	float3 camFwdNear = camFwd * camNear;
	float3 topLeft	= camFwdNear - toRight + toTop;
	float camScale	= length (topLeft) * camFar/camNear;
	
	topLeft = normalize(topLeft);
	topLeft *= camScale;
	
	float3 topRight = camFwdNear + toRight + toTop;
	topRight = normalize(topRight);
	topRight *= camScale;
	
	float3 bottomRight = camFwdNear + toRight - toTop;
	bottomRight = normalize(bottomRight);
	bottomRight *= camScale;
	
	float3 bottomLeft = camFwdNear - toRight - toTop;
	bottomLeft = normalize(bottomLeft);
	bottomLeft *= camScale;

	float4x4 frustumCorners = {
		float4(	topLeft,	0),
		float4(	topRight,	0),
		float4(	bottomRight,0),
		float4(	bottomLeft,	0)
	};

	return frustumCorners[index];
}

// Based on Unity The Black Smith AtmosphericScattering.cs script
inline float3 ViewportCorners (float2 uv)
{
	float dy = tanFov;
	float dx = dy * camAspect; 
	
	float3 vpCenter	= camFwd * camFar;
	float3 vpRight	= camRgt * (dx * camFar);
	float3 vpUp		= camUp * (dy * camFar);

	float3 u_ViewportCorner	= vpCenter - vpRight - vpUp;
	float3 u_ViewportRight	= vpRight * 2;
	float3 u_ViewportUp		= vpUp * 2;
	
	return u_ViewportCorner + uv.x * u_ViewportRight + uv.y * u_ViewportUp;
}

// Calculate camera view in world space via uv input
inline float3 UVtoViewDir (float2 uv)
{
	float2 camData = float2(camAspect * tanFov, tanFov);
	float3 v = float3( camData * (uv * 2 - 1), 1);
	v /= length(v);
	
	return mul((float3x3)unity_CameraToWorld, v);
}

// Same as UVtoViewDir() function with distance output
inline float3 UVtoViewDir (float2 uv, out float dist)
{
	float2 camData = float2(camAspect * tanFov, tanFov);
	float3 v = float3( camData * (uv * 2 - 1), 1);
	dist = length(v);
	v /= dist;
	return mul((float3x3)unity_CameraToWorld, v);

}
#endif