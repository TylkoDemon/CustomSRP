﻿Shader "CustomSRP/SRP0400/UnlitOpaque"
{
	Properties
	{
		_MainTex ("_MainTex (RGBA)", 2D) = "white" {}
		_Color("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			Tags { "LightMode" = "SRP0400_Pass" }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "../_General/ShaderLibrary/Scratch/Scratch.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
    			float3 normalOS : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 normalWS : NORMAL;
				float3 positionWS : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			// Declaring our per-material properties in a constant buffer will allow the new SRP batcher to function.
			// It's a good habit to get into early, as it's an easy performance win that doesn't obscure your code.
			CBUFFER_START(UnityPerMaterial)
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			CBUFFER_END

			#define MAXLIGHTCOUNT 8

			CBUFFER_START(_LightBuffer)
				float4 _LightColorArray[MAXLIGHTCOUNT];
				float4 _LightDataArray[MAXLIGHTCOUNT];
				float4 _LightSpotDirArray[MAXLIGHTCOUNT];
			CBUFFER_END
			
			v2f vert (appdata v)
			{
				v2f o;
				float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
				float4 positionCS = TransformWorldToHClip(positionWS);
		
				o.vertex = positionCS;
				o.positionWS = positionWS;
				o.normalWS = TransformObjectToWorldNormal(v.normalOS);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			float4 frag (v2f IN) : SV_Target
			{
				float4 albedo = tex2D(_MainTex, IN.uv) * _Color;

				for (int i = 0; i < MAXLIGHTCOUNT; i++) 
				{
					if (_LightColorArray[i].w == -1) //-1 is directional
					{
						albedo.rgb += ShadeDirectionalLight(IN.normalWS, albedo, _LightDataArray[i].xyz, _LightColorArray[i]);
					}
					else if (_LightColorArray[i].w == -2) //-2 is pointlight
					{
						albedo.rgb += ShadePointLight(IN.normalWS, albedo, IN.positionWS, _LightDataArray[i].xyz, _LightDataArray[i].w, _LightColorArray[i]);
					}
					else //Spotlight
					{
						albedo.rgb += ShadeSpotLight(IN.normalWS, albedo, IN.positionWS, _LightDataArray[i], _LightSpotDirArray[i], _LightColorArray[i]);
					}
				}
				
				return albedo;
			}
			ENDHLSL
		}
	}
}