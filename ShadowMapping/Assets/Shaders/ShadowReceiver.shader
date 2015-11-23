Shader "kokichi/Hidden/PostFX/ShadowReceiver" {
 Properties {
 	_MainTex ("Base (RGB)", 2D) = "white" {}
 	_Color("Main Color", Color) = (1,1,1,1)
 }
 SubShader {
	  Tags { "RenderType"="Opaque" }
	  
	  Pass {
		  CGPROGRAM


		  #pragma vertex vert
		  #pragma fragment frag
//		
//		  #pragma target 3.0
		  #include "UnityCG.cginc"
		  #pragma multi_compile HARD_SHADOW SOFT_SHADOW_2x2 SOFT_SHADOW_4Samples SOFT_SHADOW_4x4 
//		  #pragma multi_compile HARD_SHADOW SOFT_SHADOW_2x2 SOFT_SHADOW_4Samples 
		  uniform float4 _Color;
		  uniform fixed _bias;
		  uniform fixed _strength;
		  uniform fixed _farplaneScale;
		  uniform fixed _texmapScale;
		  uniform float4x4 _depthV;
		  uniform float4x4 _depthVPBias;
		  uniform sampler2D _kkShadowMap;
		  uniform sampler2D _MainTex;
	
		  struct v2f {
			   float4 position : SV_POSITION;
			   float2 uv : TEXCOORD0;
			   float4 shadowCoord : TEXCOORD1;
		  };
		  
		  
		  v2f vert(appdata_base v )
		  {
			   v2f o;
			   o.position = mul(UNITY_MATRIX_MVP, v.vertex);
			   o.shadowCoord = mul(_depthVPBias, mul(_Object2World, v.vertex));
			   o.shadowCoord.z = -(mul(_depthV, mul(_Object2World, v.vertex)).z * _farplaneScale);
			   o.uv = v.texcoord;
			   return o;
		  }
	

		  

	  		float4 offset_lookup(sampler2D map, float4 loc, float2 offset)
			{
				return tex2D(map, loc.xy + offset * _texmapScale);
			}
			
		   half4 fragPCF4x4(v2f IN)
		  {
		  		float sum = 0;
		  		float x,y;
		  		for (y = -1.5; y <= 1.5; y += 1.0)
					  for (x = -1.5; x <= 1.5; x += 1.0)
					  {
					  		float depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, float2(x,y)));
		  					float shade =  max(step(IN.shadowCoord.z - _bias, depth), _strength);
		  					sum += shade;
					  }
		  		sum = sum / 16.0;
		  	    return sum * tex2D(_MainTex, IN.uv) * _Color;
		  }
		  
		   half4 fragPCF4Samples(v2f IN)
		  {
		  		float sum = 0;
		  		float2 offset = (float)(frac(IN.shadowCoord.xy * 0.5) > 0.25);  // mod
				offset.y += offset.x;  // y ^= x in floating point
//				   if (offset.y > 1.1)
//				  offset.y = 0;
				  float depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, offset + float2(-1.5, 0.5)));
		  		  sum += max(step(IN.shadowCoord.z - _bias, depth), _strength) * 0.25;
		  		  
		  		  depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, offset + float2(0.5, 0.5)));
		  		  sum += max(step(IN.shadowCoord.z - _bias, depth), _strength) * 0.25;
		  		  
		  		  depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, offset + float2(-1.5, -1.5)));
		  		  sum += max(step(IN.shadowCoord.z - _bias, depth), _strength) * 0.25;
		  		  
		  		  depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, offset + float2(0.5, -1.5)));
		  		  sum += max(step(IN.shadowCoord.z - _bias, depth), _strength) * 0.25;
		  		  
		  	    return sum * tex2D(_MainTex, IN.uv) * _Color;
		  }
		  
		   half4 fragPCF2x2(v2f IN)
		  {
		  		float sum = 0;
		  		float x,y;
		  		for (y = -0.5; y <= 0.5; y += 1.0)
					  for (x = -0.5; x <= 0.5; x += 1.0)
					  {
					  		float depth = DecodeFloatRGBA(offset_lookup(_kkShadowMap, IN.shadowCoord, float2(x,y)));
		  					float shade =  max(step(IN.shadowCoord.z - _bias, depth), _strength);
		  					sum += shade;
					  }
		  		sum = sum / 4.0;
		  	    return sum * tex2D(_MainTex, IN.uv) * _Color;
		  }
		  
		  half4 frag(v2f IN) : COLOR
		  {
#ifdef HARD_SHADOW
		  		float depth = DecodeFloatRGBA(tex2D(_kkShadowMap, IN.shadowCoord.xy));
		  		float shade =  max(step(IN.shadowCoord.z - _bias, depth), _strength);
		  	    return shade * tex2D(_MainTex, IN.uv) * _Color;
#endif

#ifdef SOFT_SHADOW_2x2
			return fragPCF2x2(IN);
#endif

#ifdef SOFT_SHADOW_4Samples
			return fragPCF4Samples(IN);
#endif

#ifdef SOFT_SHADOW_4x4
			return fragPCF4x4(IN);
#endif
		  }
	  ENDCG
	  }
 }
 
}