Shader "kokichi/Hidden/PostFX/RenderDepthTexture" {
 Properties {
 }
 SubShader {
	  Tags { "RenderType"="Opaque" }
	  
	  Pass {
		  CGPROGRAM
		  #pragma vertex vert
		  #pragma fragment frag
		  #include "UnityCG.cginc"
		  
		  
		  struct v2f {
			   float4 position : SV_POSITION;
			   fixed depth : TEXCOORD0;
		  };
		  
	  
	  	 v2f vert(appdata_base v )
		  {
			   v2f o;
			   o.position = mul(UNITY_MATRIX_MVP, v.vertex);
			   o.depth = COMPUTE_DEPTH_01;
			   return o;
		  }
		  
		  float4 frag(v2f IN) : COLOR
		  {
		  	   return (EncodeFloatRGBA(min(IN.depth,0.9999991)));
		  }	  
		 
	  
	  ENDCG
	  }
 }
 
}