Shader "Joshuarox100/Revolving Fade" {
	Properties {
		_MainTex ("Albedo", 2D) = "white" {}
		_EmissionMap ("Emission", 2D) = "black" {}
		_EmissiveStrength ("Emissive Strength", Range(0, 1)) = 0.5
		_Speed ("Speed", Float) = 10
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }
		LOD 200
		Cull [_Cull]

		CGPROGRAM
		#pragma surface surf Lambert alpha:fade vertex:vert
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _EmissionMap;

		struct Input {
			float2 uv_MainTex;
		};

		float _Speed;
		float _EmissiveStrength;

		void vert (inout appdata_full v) {
			v.texcoord.xy -= 0.5;
			float s = -sin(_Speed * _Time);
			float c = cos(_Speed * _Time);
			float2x2 rotationMatrix = float2x2(c, -s, s, c);
			rotationMatrix *= 0.5;
			rotationMatrix += 0.5;
			rotationMatrix = (rotationMatrix * 2) - 1;
			v.texcoord.xy = mul(v.texcoord.xy, rotationMatrix);
			v.texcoord.xy += 0.5;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			fixed4 e = tex2D (_EmissionMap, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Emission = e.rgb * _EmissiveStrength * 2;
			o.Alpha = c.a;
		}
		ENDCG
	}
	CustomEditor "RevolvingFadeGUI"
	FallBack "Transparent/VertexLit"
}
