/*=============================================================================
	Atmosphere.cginc : Functions and variables only used in Atmospheric Scattering

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
#ifndef USKY_ATMOSPHERE_INCLUDED
#define USKY_ATMOSPHERE_INCLUDED

// DEFAULT AND CLEAR SKY
//const static float HR = 8.0;
//const static float HM = 1.2; 
// PARTLY CLOUDY
//const static float HM = 3.0;

// Default value : (5.8e-3, 1.35e-2, 3.31e-2) of sea level wavelengths (680, 550, 440)
uniform float4	betaR;

uniform sampler2D _Transmittance;
uniform sampler2D _Inscatter;

uniform float	_uSkyExposure;
uniform float	_uSkyMieG;
uniform float	_uSkyMieScale;
// x = NightFade, y = MoonFade, z = OuterSpaceIntensity 
uniform float3	_uSkyNightParams;
uniform float4	_SunDirSize;
uniform float	_uSkyGroundOffset;
uniform float	_uSkyAltitudeScale;
uniform float	_uSkyAtmosphereThickness;
uniform float	_uSkySkyboxOcean;

// Image effects parameters
uniform float _AtmosphereFogMultiplier, _AtmosphereWorldScale, _NearScatterPush;

const static float Rg = 6360000.0;
const static float Rt = 6420000.0;
const static float RL = 6421000.0;

uniform int RES_R; 				// 3D texture depth
const static int RES_MU = 128; 	// height of the texture
const static int RES_MU_S = 32; // width per table
const static int RES_NU = 8;	// table per texture depth

const static float3 EARTH_POS = float3(0.0, 6360010.0, 0.0);
const static float SUN_BRIGHTNESS = 40.0;

// medium precision for mobile
const static half SUN_BRIGHTNESS_MEDIUMP = 40.0;
uniform half3 betaR_Mediump;
uniform half _uSkyExposure_Mediump;
uniform half3 _uSkyNightParams_Mediump;

#define TRANSMITTANCE_NON_LINEAR
#define INSCATTER_NON_LINEAR

/* Whether to attempt to fix small pixels artifacts appears at the horizion rendering.
 * Enable this option will cost more calculation in shader. */
#define HORIZON_FIX


//--------------------------------------------------------------------------------------------------

float3 hdr(float3 L) 
{
    L.r = L.r < 1.413 ? pow(L.r * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.r);
    L.g = L.g < 1.413 ? pow(L.g * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.g);
    L.b = L.b < 1.413 ? pow(L.b * 0.38317, 1.0 / 2.2) : 1.0 - exp(-L.b);
    return L;
}

// switch different tonemapping methods between day and night
float3 hdr2(float3 L) 
{
    L = lerp(hdr(L),1.0 - exp(-L), _uSkyNightParams.x);
    return L;
}

// ported from unity tonemapping: Photographic formula
half3 HDRtoRGB (half3 c)
{
	return 1 - exp2(-c);
}

// 4D data in Texture2D format
float4 Texture4D(sampler2D table, float r, float mu, float muS, float nu)
{
   	float H = sqrt(Rt * Rt - Rg * Rg);
   	float rho = sqrt(r * r - Rg * Rg);
#ifdef INSCATTER_NON_LINEAR
    float rmu = r * mu;
    float delta = rmu * rmu - r * r + Rg * Rg;
    float4 cst = rmu < 0.0 && delta > 0.0 ? float4(1.0, 0.0, 0.0, 0.5 - 0.5 / RES_MU) : float4(-1.0, H * H, H, 0.5 + 0.5 / RES_MU);     
    float uR = 0.5 / RES_R + rho / H * (1.0 - 1.0 / RES_R);
    float uMu = cst.w + (rmu * cst.x + sqrt(delta + cst.y)) / (rho + cst.z) * (0.5 - 1.0 / float(RES_MU));

    // paper formula
    //float uMuS = 0.5 / RES_MU_S + max((1.0 - exp(-3.0 * muS - 0.6)) / (1.0 - exp(-3.6)), 0.0) * (1.0 - 1.0 / RES_MU_S);
    // better formula
    float uMuS = 0.5 / RES_MU_S + (atan(max(muS, -0.1975) * tan(1.26 * 1.1)) / 1.1 + (1.0 - 0.26)) * 0.5 * (1.0 - 1.0 / RES_MU_S);

if (_uSkySkyboxOcean == 0)
	uMu = rmu < 0.0 && delta > 0.0 ? 0.975 : uMu * 0.975 + 0.015 * uMuS; // 0.975 to fix the horizion seam. 0.015 to fix zenith artifact

#else
    float uR = 0.5 / RES_R + rho / H * (1.0 - 1.0 / RES_R);
    float uMu = 0.5 / RES_MU + (mu + 1.0) / 2.0 * (1.0 - 1.0 / RES_MU);
    float uMuS = 0.5 / RES_MU_S + max(muS + 0.2, 0.0) / 1.2 * (1.0 - 1.0 / RES_MU_S);
#endif
    float lep = (nu + 1.0) / 2.0 * (RES_NU - 1.0);
    float uNu = floor(lep);
    lep = lep - uNu;

    //Original 3D lookup
    //return tex3D(table, float3((uNu + uMuS) / RES_NU, uMu, uR)) * (1.0 - lep) + tex3D(table, float3((uNu + uMuS + 1.0) / RES_NU, uMu, uR)) * lep;

    float uNu_uMuS = uNu + uMuS;

#ifdef USKY_MULTISAMPLE  
    //new 2D lookup
	float u_0 = floor(uR * RES_R) / RES_R;
	float u_1 = floor(uR * RES_R + 1.0) / RES_R;
	float u_frac = frac(uR * RES_R);

	// pre-calculate uv
	float uv_0X = uNu_uMuS / RES_NU;
	float uv_1X = (uNu_uMuS + 1.0) / RES_NU;
	float uv_0Y = uMu / RES_R + u_0;
	float uv_1Y = uMu / RES_R + u_1;
	float OneMinusLep = 1.0 - lep;

	float4 A = tex2D(table, float2(uv_0X, uv_0Y)) * OneMinusLep + tex2D(table, float2(uv_1X, uv_0Y)) * lep;	
	float4 B = tex2D(table, float2(uv_0X, uv_1Y)) * OneMinusLep + tex2D(table, float2(uv_1X, uv_1Y)) * lep;	

	return A * (1.0-u_frac) + B * u_frac;

#else	
	return tex2D(table, float2(uNu_uMuS / RES_NU, uMu)) * (1.0 - lep) + tex2D(table, float2((uNu_uMuS + 1.0) / RES_NU, uMu)) * lep;	
#endif

}

//--------------------------------------------------------------------------------------------------

float3 GetMie(float4 rayMie) 
{	
	// approximated single Mie scattering (cf. approximate Cm in paragraph "Angular precision")
	// rayMie.rgb=C*, rayMie.w=Cm,r
   	return rayMie.rgb * rayMie.w / max(rayMie.r, 1e-4) * (betaR.r / betaR.xyz);
}

float PhaseFunctionR(float mu) // original code (not in use)
{
	// Rayleigh phase function
    return (3.0 / (16.0 * UNITY_PI)) * (1.0 + mu * mu);
}
float PhaseFunctionR() // optimized
{
	// Rayleigh phase function without multiply (1.0 + mu * mu)
	// We will multiply (1.0 + mu * mu) together with Mie phase later.
    return 3.0 / (16.0 * UNITY_PI);
}
/*
float PhaseFunctionM(float mu) // original code
{
	// Mie phase function
  return 1.5 * 1.0 / (4.0 * UNITY_PI) * (1.0 - mieG*mieG) * pow(1.0 + (mieG*mieG) - 2.0*mieG*mu, -3.0/2.0) * (1.0 + mu * mu) / (2.0 + mieG*mieG);
}
*/
float PhaseFunctionM(float mu, float3 miePhase_g)  // optimized
{
	// Mie phase function (optimized)
	// Precomputed PhaseFunctionG() with constant values in vertex program and pass them in here
	// we will multiply (1.0 + mu * mu) together with Rayleigh phase later.
	return miePhase_g.x / pow( miePhase_g.y - miePhase_g.z * mu, 1.5 );
}

float3 PhaseFunctionG(float g, float scale) 
{
	// Mie phase G function and Mie scattering scale, (compute this function in Vertex program)
	float g2 = g * g;
	return float3(scale * 1.5 * (1.0 / (4.0 * UNITY_PI)) * ((1.0 - g2) / (2.0 + g2)), 1.0 + g2, 2.0 * g);
}

// Sun Disk
float SunFunction(float mu, float3 miePhase_g)
{
	return PhaseFunctionM(mu, miePhase_g) * (1.0 + mu * mu);
}


// ---------------------------------------------------------------------------- 
// TRANSMITTANCE FUNCTIONS 
// ---------------------------------------------------------------------------- 
	// transmittance(=transparency) of atmosphere for infinite ray (r,mu)
	// (mu=cos(view zenith angle)), intersections with ground ignored
float3 Transmittance(float r, float mu) 
{
   	float uR, uMu;
#ifdef TRANSMITTANCE_NON_LINEAR
    uR = sqrt((r - Rg) / (Rt - Rg));
    uMu = atan((mu + 0.15) / (1.0 + 0.15) * tan(1.5)) / 1.5;
#else
    uR = (r - Rg) / (Rt - Rg);
    uMu = (mu + 0.15) / (1.0 + 0.15);
#endif    
    return tex2D(_Transmittance, float2(uMu, uR)).rgb;
}


// ---------------------------------------------------------------------------- 
// INSCATTER FUNCTIONS (SKYBOX)
// ---------------------------------------------------------------------------- 
	// scattered sunlight between two points
	// camera=observer
	// viewdir=unit vector towards observed point
	// sundir=unit vector towards the sun
	// return scattered light
	
	// optimized scattering phase formula

float3 SkyRadiance(float3 camera, float3 viewdir, float nu, float3 MiePhase_g, out float3 extinction)
{
	camera += EARTH_POS;

   	float3 result = float3(0,0,0);
    float r = length(camera);
    float rMu = dot(camera, viewdir);
    float mu = rMu / r ;

    float deltaSq = sqrt(rMu * rMu - r * r + Rt*Rt);
    float din = max(-rMu - deltaSq, 0.0);
    
    if (din > 0.0) 
    {
       	camera += din * viewdir;
       	rMu += din;
       	mu = rMu / Rt;
       	r = Rt;
    }
    
//    float nu = dot(viewdir, _SunDirSize.xyz); // nu value is from function input
    float muS = dot(camera, _SunDirSize.xyz) / r;

    float4 inScatter = Texture4D(_Inscatter, r, rMu / r, muS, nu);

    extinction = Transmittance(r, mu); 

    if(r <= Rt ) 
    {
        float3 inScatterM = GetMie(inScatter);
        float phase = PhaseFunctionR();
        float phaseM = PhaseFunctionM(nu, MiePhase_g);
        result = (inScatter.rgb * phase + inScatterM * phaseM)*(1.0 + nu * nu);
    }
    else
    {
    	result = float3(0,0,0);
    	extinction = float3(1,1,1);
    }

    return result * SUN_BRIGHTNESS;
}

// ---------------------------------------------------------------------------- 
// INSCATTER FUNCTIONS (IMAGE EFFECTS)
// ---------------------------------------------------------------------------- 
	// single scattered sunlight between two points
	// camera=observer
	// point=point on the ground
	// sundir=unit vector towards the sun
	// return scattered light and extinction coefficient
	
	// optimized scattering phase formula
	 
float3 InScattering(float3 camera, float3 _point, float3 MiePhase_g, inout float3 extinction ) 
{
    float3 result = float3(0,0,0);

    float worldScale = max( _AtmosphereWorldScale, 1.0);

	camera.y	*= worldScale;
	_point		*= worldScale;
    camera.y	+= Rg;
    _point.y	+= Rg ;
                                                                                         
    float3 viewdir = _point - camera; 
    float d = length(viewdir);
    viewdir = viewdir / d;
    float r = length(camera);

    float rMu = dot(camera, viewdir); 
    float mu = rMu / r;   
    _point -= viewdir * clamp(_NearScatterPush, 0.0, d);

    float deltaSq = sqrt(rMu * rMu - r * r + Rt*Rt);
    float din = max(-rMu - deltaSq, 0.0);
    
    if (din > 0.0) // if camera in space and ray intersects atmosphere
    {
        camera += din * viewdir;
        rMu += din;
        mu = rMu / Rt;
        r = Rt;
        d -= din;
    }

    if (r <= Rt) // if ray intersects atmosphere
    {
        float nu = dot(viewdir, _SunDirSize.xyz);
        float muS = dot(camera, _SunDirSize.xyz) / r; 

        float4 inScatter;
        
		// avoids artifact issue when atmosphere thickness value is too high
		float HeightOffset = Rg + 600 ; // default
//		float HeightOffset = Rg + 1500 * _uSkyAtmosphereThickness;
		 
        if (r < HeightOffset) 
        {
            // avoids imprecision problems in aerial perspective near ground
            float f = HeightOffset / r;
            r = r * f;
            rMu = rMu * f;
            _point = _point * f;
        }

        float r1 = length(_point);
        float rMu1 = dot(_point, viewdir);
        float mu1 = rMu1 / r1;
        float muS1 = dot(_point, _SunDirSize.xyz) / r1;
           
        if (mu > 0.0) 
            extinction = min(Transmittance(r, mu) / Transmittance(r1, mu1), 1.0);
        else 
            extinction = min(Transmittance(r1, -mu1) / Transmittance(r, -mu), 1.0);

#ifdef HORIZON_FIX
		// avoids imprecision problems near horizon by interpolating between two points above and below horizon
        const float EPS = 0.004;
        float lim = -sqrt(1.0 - (Rg / r) * (Rg / r));
        
        if (abs(mu - lim) < EPS) 
        {
            float a = ((mu - lim) + EPS) / (2.0 * EPS);

            mu = lim - EPS;
            r1 = sqrt(r * r + d * d + 2.0 * r * d * mu);
            mu1 = (r * mu + d) / r1;
            
            float4 inScatter0 = Texture4D(_Inscatter, r, mu, muS, nu);
            float4 inScatter1 = Texture4D(_Inscatter, r1, mu1, muS1, nu);
            float4 inScatterA = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
            
            mu = lim + EPS;
            r1 = sqrt(r * r + d * d + 2.0 * r * d * mu);
            mu1 = (r * mu + d) / r1;
            
            inScatter0 = Texture4D(_Inscatter, r, mu, muS, nu);
            inScatter1 = Texture4D(_Inscatter, r1, mu1, muS1, nu);
            float4 inScatterB = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);

            inScatter = lerp(inScatterA, inScatterB, a);

        } 
        else
#endif
        {
            float4 inScatter0 = Texture4D(_Inscatter, r, mu, muS, nu);
            float4 inScatter1 = Texture4D(_Inscatter, r1, mu1, muS1, nu);
            inScatter = max(inScatter0 - inScatter1 * extinction.rgbr, 0.0);
        }
                
        // avoids imprecision problems in Mie scattering when sun is below horizon
        inScatter.w *= smoothstep(0.00, 0.04, muS); // increased the clamped value, default (0.00, 0.02, muS);

        float3 inScatterM = GetMie(inScatter);
        float phaseR = PhaseFunctionR();
        float phaseM = PhaseFunctionM(nu, MiePhase_g);

        result = (inScatter.rgb * phaseR + inScatterM * phaseM)*(1.0 + nu * nu);        
    } else { // camera in space and ray looking in space
        result = float3(0,0,0);
        extinction = float3(1,1,1);
    }

    return result * SUN_BRIGHTNESS ;
}

// ---------------------------------------------------------------------------- 
// SKYBOX MOBILE VERSION FUNCTIONS
// ---------------------------------------------------------------------------- 
// Calculate in medium precision.

// ported from unity tonemapping: Photographic formula
half3 HDRtoLDR (half3 c)
{
	return 1.0 - exp2(-c);
}

// this function calculates in vertex program (float : high precision)
// muS is an approximation value that based on Y axis of sun direction
float Get_uMuS (float muS)
{
   	return float(0.5 / float(RES_MU_S) + (atan(max(muS, -0.1975) * tan(1.26 * 1.1)) / 1.1 + (1.0 - 0.26)) * 0.5 * (1.0 - 1.0 / float(RES_MU_S)));
	
}

half3 GetMie_Mediump(half4 rayMie) 
{	
	// approximated single Mie scattering (cf. approximate Cm in paragraph "Angular precision")
	// rayMie.rgb=C*, rayMie.w=Cm,r
   	return rayMie.rgb * rayMie.w / max(rayMie.r, 1e-4) * (betaR_Mediump.r / betaR_Mediump.xyz);
}

// Same as PhaseFunctionR (), but calculate here with medium precision	
half PhaseFunctionR_Mediump()
{
	// Rayleigh phase function without multiply (1.0 + mu * mu)
    return 3.0 / (16.0 * UNITY_PI);
}

// Same as PhaseFunctionM (), but calculate here with medium precision
half PhaseFunctionM_Mediump(half mu, half3 miePhase_g)  // optimized
{
	// Mie phase function (optimized)
	return miePhase_g.x / pow( miePhase_g.y - miePhase_g.z * mu, 1.5 );
}

half3 Texture2D_Mobile (float skyDirY, half nu, float2 Mu_uMuS, half3 miePhase_g, out half3 extinction)
{
	float Mu = Mu_uMuS.x;
	// we could calculate the uMu in vertex program, however we are getting jaggy artifacts of sky gradient
	// so we calculate this in fragment get better smooth sky gradient result.
	float uMu = 0.5 + (-Mu + sqrt(Mu * Mu + 0.766))/ 1.85 ;
	float2 uv = float2 (Mu_uMuS.y, uMu);
	
	// no earth shadow (uv reads one table only)
    half4 inscatter = tex2D(_Inscatter, uv);			    
	
	half3 inscatterM = GetMie_Mediump(inscatter);
	half phaseR = PhaseFunctionR_Mediump();
	half phaseM = PhaseFunctionM_Mediump(nu, miePhase_g);
	
	// read ground level extinction data only.
//	extinction = tex2D(_Transmittance, half2(skyDirY + 0.71, 0.0)).rgb;

	// using inscatterM instead for faster rendering.
	extinction = inscatterM;

	return half3(inscatter.rgb * phaseR + inscatterM * phaseM) * ((1.0 + nu * nu)* SUN_BRIGHTNESS_MEDIUMP);

}

#endif // USKY_ATMOSPHERE_INCLUDED