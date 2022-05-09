#ifndef USKY_ATMOSPHERE_LAYERS
#define USKY_ATMOSPHERE_LAYERS

// HARDCODED : unroll style to split total of 32 depth layers into Texture 2D.
//-----------------------------------------------------------------

// 2 layer (upper half = clouds level layer, lower half = ground level layer) 
// Texture size is 256 x 256
float3 Layer2 (float2 coords, int RES_R)
{
	return coords.y > 0.5? float3(coords.x, coords.y * RES_R -1, 2):float3(coords.x, coords.y * RES_R, 0);
}

// 4 layer
// Texture size = 256 x 512
float3 Layer4 (float2 coords, int RES_R)
{
    return	coords.y > 0.75?	float3(coords.x, coords.y * RES_R -3, 8 ):	// atmosphere level layer
    		coords.y > 0.5 ?	float3(coords.x, coords.y * RES_R -2, 4 ): 
			coords.y > 0.25?	float3(coords.x, coords.y * RES_R -1, 2 ): 
								float3(coords.x, coords.y * RES_R	, 0 );	// ground level layer
}

// 8 layer
// Texture size = 256 x 1024
float3 Layer8 (float2 coords, int RES_R)
{
    return	coords.y > 0.875?	float3(coords.x, coords.y * RES_R -7, 24):	// space level layer
    		coords.y > 0.75 ?	float3(coords.x, coords.y * RES_R -6, 20):	
    		coords.y > 0.625?	float3(coords.x, coords.y * RES_R -5, 16): 
			coords.y > 0.5  ?	float3(coords.x, coords.y * RES_R -4, 12):
			coords.y > 0.375?	float3(coords.x, coords.y * RES_R -3, 8 ):	// atmosphere level layer
    		coords.y > 0.25 ?	float3(coords.x, coords.y * RES_R -2, 4 ): 
			coords.y > 0.125?	float3(coords.x, coords.y * RES_R -1, 2 ): 
								float3(coords.x, coords.y * RES_R	, 0 );	// ground level layer
}

// 16 layer
// Texture size = 256 x 2048
float3 Layer16 (float2 coords, int RES_R)
{
    return	coords.y > (15.0/16)?	float3(coords.x, coords.y * RES_R -15, 30): // space level layer
			coords.y > (14.0/16)?	float3(coords.x, coords.y * RES_R -14, 28):	
    		coords.y > (13.0/16)?	float3(coords.x, coords.y * RES_R -13, 26):	
    		coords.y > (12.0/16)?	float3(coords.x, coords.y * RES_R -12, 24): 
			coords.y > (11.0/16)?	float3(coords.x, coords.y * RES_R -11, 22): 
			coords.y > (10.0/16)?	float3(coords.x, coords.y * RES_R -10, 20):	
    		coords.y > ( 9.0/16)?	float3(coords.x, coords.y * RES_R - 9, 18): 
			coords.y > ( 8.0/16)?	float3(coords.x, coords.y * RES_R - 8, 16): // atmosphere level layer
			coords.y > ( 7.0/16)?	float3(coords.x, coords.y * RES_R - 7, 14):	
    		coords.y > ( 6.0/16)?	float3(coords.x, coords.y * RES_R - 6, 12):	
    		coords.y > ( 5.0/16)?	float3(coords.x, coords.y * RES_R - 5, 10): 
			coords.y > ( 4.0/16)?	float3(coords.x, coords.y * RES_R - 4, 8 ): 
			coords.y > ( 3.0/16)?	float3(coords.x, coords.y * RES_R - 3, 6 ):	
    		coords.y > ( 2.0/16)?	float3(coords.x, coords.y * RES_R - 2, 4 ): 
			coords.y > ( 1.0/16)?	float3(coords.x, coords.y * RES_R - 1, 2 ): 
									float3(coords.x, coords.y * RES_R	 , 0 );	// ground level layer

}

// 32 layer (full)
// Texture size = 256 x 4096
float3 Layer32 (float2 coords, int RES_R)
{
    return	coords.y > (31.0/32)?	float3(coords.x, coords.y * RES_R -31, 31):	// space level layer
    		coords.y > (30.0/32)?	float3(coords.x, coords.y * RES_R -30, 30): 
			coords.y > (29.0/32)?	float3(coords.x, coords.y * RES_R -29, 29):	
    		coords.y > (28.0/32)?	float3(coords.x, coords.y * RES_R -28, 28):	
    		coords.y > (27.0/32)?	float3(coords.x, coords.y * RES_R -27, 27): 
			coords.y > (26.0/32)?	float3(coords.x, coords.y * RES_R -26, 26): 
			coords.y > (25.0/32)?	float3(coords.x, coords.y * RES_R -25, 25):	
    		coords.y > (24.0/32)?	float3(coords.x, coords.y * RES_R -24, 24): 
			coords.y > (23.0/32)?	float3(coords.x, coords.y * RES_R -23, 23):
			coords.y > (22.0/32)?	float3(coords.x, coords.y * RES_R -22, 22):	
    		coords.y > (21.0/32)?	float3(coords.x, coords.y * RES_R -21, 21):	
    		coords.y > (20.0/32)?	float3(coords.x, coords.y * RES_R -20, 20): 
			coords.y > (19.0/32)?	float3(coords.x, coords.y * RES_R -19, 19): 
			coords.y > (18.0/32)?	float3(coords.x, coords.y * RES_R -18, 18):	
    		coords.y > (17.0/32)?	float3(coords.x, coords.y * RES_R -17, 17): 
			coords.y > (16.0/32)?	float3(coords.x, coords.y * RES_R -16, 16):  // atmosphere level layer
    		coords.y > (15.0/32)?	float3(coords.x, coords.y * RES_R -15, 15):
			coords.y > (14.0/32)?	float3(coords.x, coords.y * RES_R -14, 14):	
    		coords.y > (13.0/32)?	float3(coords.x, coords.y * RES_R -13, 13):	
    		coords.y > (12.0/32)?	float3(coords.x, coords.y * RES_R -12, 12): 
			coords.y > (11.0/32)?	float3(coords.x, coords.y * RES_R -11, 11): 
			coords.y > (10.0/32)?	float3(coords.x, coords.y * RES_R -10, 10):	
    		coords.y > ( 9.0/32)?	float3(coords.x, coords.y * RES_R - 9, 9 ): 
			coords.y > ( 8.0/32)?	float3(coords.x, coords.y * RES_R - 8, 8 ): 
			coords.y > ( 7.0/32)?	float3(coords.x, coords.y * RES_R - 7, 7 ):	
    		coords.y > ( 6.0/32)?	float3(coords.x, coords.y * RES_R - 6, 6 ):	
    		coords.y > ( 5.0/32)?	float3(coords.x, coords.y * RES_R - 5, 5 ): 
			coords.y > ( 4.0/32)?	float3(coords.x, coords.y * RES_R - 4, 4 ): 
			coords.y > ( 3.0/32)?	float3(coords.x, coords.y * RES_R - 3, 3 ):	
    		coords.y > ( 2.0/32)?	float3(coords.x, coords.y * RES_R - 2, 2 ): 
			coords.y > ( 1.0/32)?	float3(coords.x, coords.y * RES_R - 1, 1 ): 
									float3(coords.x, coords.y * RES_R	 , 0 );	// ground level layer

}


float3 MultiLayers (float2 coords, int RES_R)
{
	if (RES_R == 32){
		return	Layer32	(coords, RES_R);
	}else
	if (RES_R == 16){
		return	Layer16	(coords, RES_R);
	}else
	if (RES_R == 8 ){
		return	Layer8	(coords, RES_R);
	}else
	if (RES_R == 4 ){
		return	Layer4	(coords, RES_R);
	}else
		return	Layer2	(coords, RES_R);
}

/*
// TODO : Working in progress
float3 DynamicLayers (float2 coords, int RES_R)
{

	float3 uvLayer = float3(0,0,0);

	for (int i = 0; i < RES_R; i++) 
	{
		float I = (RES_R - 1) - i;
		coords.y = (coords.y > (I/RES_R))? mod(coords.y, (I/RES_R)): coords.y;
		uvLayer = float3(coords.x, coords.y * RES_R - I, I);	
	}
	return uvLayer;
}
*/

#endif