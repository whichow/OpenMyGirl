// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/*=============================================================================
	AtmospherePrecompute.cginc : Precompute data for Atmospheric Scattering

	This code contains embedded portions of free sample source code from 
	http://www-evasion.imag.fr/Membres/Eric.Bruneton/PrecomputedAtmosphericScattering2.zip, Author: Eric Bruneton, 
	08/16/2011, Copyright (c) 2008 INRIA, All Rights Reserved, which have been altered from their original version.

	Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

    1. Redistributions of source code must retain the above copyright notice, 
	   this list of conditions and the following disclaimer.
    2. Redistributions in binary form must reproduce the above copyright notice, 
	   this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
    3. Neither the name of the copyright holders nor the names of its
       contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.
       
	Author: Eric Bruneton
	Ported to Unity by Justin Hawkins 2014
	Altered in uSkyPro by Michael Lam 2016
=============================================================================*/
#ifndef USKY_ATMOSPHERE_PRECOMPUTED
#define USKY_ATMOSPHERE_PRECOMPUTED

#include "AtmosphereCommon.cginc"
#include "AtmosphereLayers.cginc"

// vertex shader entry point
struct AtmosphereVSOut {
	float4 vertex	: SV_POSITION;
	float2 uv		: TEXCOORD0;
};

void MainVS (
	in float4 InPosition : POSITION,
	in float2 InTexCoord : TEXCOORD0,
	out AtmosphereVSOut Out
	)
{
	Out.vertex = UnityObjectToClipPos(InPosition);
	Out.uv = InTexCoord.xy;
}

// pixel shader entry point
// ---------------------------------------------------------------------------- 
// TRANSMITTANCE FUNCTIONS 
// ---------------------------------------------------------------------------- 
float OpticalDepth(float H, float r, float mu) 
{ 
    float result = 0.0; 
    float dx = Limit(r, mu) / float(TRANSMITTANCE_INTEGRAL_SAMPLES); 
    float xi = 0.0; 
    float yi = exp(-(r - Rg) / H); 
    
    for (int i = 1; i <= TRANSMITTANCE_INTEGRAL_SAMPLES; ++i) 
    { 
        float xj = float(i) * dx; 
        float yj = exp(-(sqrt(r * r + xj * xj + 2.0 * xj * r * mu) - Rg) / H); 
        result += (yi + yj) / 2.0 * dx; 
        xi = xj; 
        yi = yj; 
    }
     
    return mu < -sqrt(1.0 - (Rg / r) * (Rg / r)) ? 1e9 : result; 
} 

void TransmittancePS(AtmosphereVSOut IN, out float4 OutColor : SV_Target0)
{
    float r, muS; 
    GetTransmittanceRMu(IN.uv, r, muS); 

    float3 depth = betaR.xyz * OpticalDepth(HR, r, muS) + betaMEx * OpticalDepth(HM, r, muS); 
	OutColor = float4(exp(-depth), 0.0); // Eq (5)
}

// ---------------------------------------------------------------------------- 
// INSCATTER FUNCTIONS 
// ---------------------------------------------------------------------------- 
void Integrand(float r, float mu, float muS, float nu, float t, out float3 ray, out float mie) 
{ 
    ray = float3(0,0,0); 
    mie = 0.0; // single channel only
    float ri = sqrt(r * r + t * t + 2.0 * r * mu * t); 
//    float muSi = (nu * t + muS * r) / ri ; // original code
    float muSi = (nu * t + muS * r) / (ri * lerp(1.0, betaR.w, max(0.0, muS))); // added betaR.w to fix the Rayleigh Offset artifacts issue
    ri = max(Rg, ri); 
    UNITY_FLATTEN
    if (muSi >= -sqrt(1.0 - Rg * Rg / (ri * ri ))) 
    { 
        float3 ti = Transmittance(r, mu, t) * Transmittance(ri, muSi); 
        ray = exp(-(ri - Rg) / HR) * ti; 
        mie = exp(-(ri - Rg) / HM) * ti.x; // only calc the red channel
    } 
} 

void Inscatter(float r, float mu, float muS, float nu, out float3 ray, out float mie) 
{ 
    ray = float3(0,0,0); 
    mie = 0.0; // single channel only
    float dx = Limit(r, mu) / float(INSCATTER_INTEGRAL_SAMPLES); 
    float xi = 0.0; 
    float3 rayi; 
    float miei; 
    Integrand(r, mu, muS, nu, 0.0, rayi, miei); 

    for (int i = 1; i <= INSCATTER_INTEGRAL_SAMPLES; ++i) 
    { 
        float xj = float(i) * dx; 
        float3 rayj; 
        float miej; 
        Integrand(r, mu, muS, nu, xj, rayj, miej); 
        
        ray += (rayi + rayj) / 2.0 * dx; 
        mie += (miei + miej) / 2.0 * dx; 
        xi = xj; 
        rayi = rayj; 
        miei = miej; 
    } 
    
    ray *= betaR.xyz; 
    mie *= betaMSca.x; 
} 

void Inscatter1PS(AtmosphereVSOut IN, out float4 OutColor : SV_Target0)
{	
    float3 ray;
    float mie; // only calc the red channel
    float4 dhdH;
    float mu, muS, nu, r;

  	float2 coords = IN.uv.xy; // range 0 ~ 1.
//	float2 coords = float2 ( IN.uv.x * float(RES_MU_S * RES_NU), IN.uv.y * float(RES_MU)); // TexelSize range

// ----------------------------------------
//  uSkyPro custom altitude layer override
// ----------------------------------------

	// Total range of depth/layers is 0 ~ 31. Texture size is 256 x 128 per layer.
	// MultiLayers() function is in "AtmosphereLayers.cginc".
	float3 uvLayer = (RES_R > 1)? MultiLayers (coords, RES_R) :	float3(coords, 1);

// ------------------------------------

	GetLayer((int)uvLayer.z, r, dhdH); 
    GetMuMuSNu(uvLayer.xy, r, dhdH, mu, muS, nu); 
  
    Inscatter(r, mu, muS, nu, ray, mie); 
    
	// store only red component of single Mie scattering (cf. 'Angular precision')
	OutColor = float4(ray,mie);
}

#endif // USKY_ATMOSPHERE_PRECOMPUTED