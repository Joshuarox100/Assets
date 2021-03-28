Shader "Joshuarox100/Animated Shader"
{
    Properties
    {
        _MainTex ("Animation", 2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Cutoff ("Alpha Cutoff", Range(0,1)) = 0.1
		_Speed ("Speed (FPS)", Float) = 10
		[Toggle(_EMISSION)] _EMISSION ("Enable Emission", Float) = 0
		[Toggle(_AUTOMATIC)] _AUTOMATIC ("Dynamic Emission", Float) = 0
		[NoScaleOffset] _EmissionMap ("Emission Map", 2D) = "white" {}
		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		_AutoEmisColor ("Emissive Color", Color) = (1,1,1,1)
		_AutoEmisThres ("Similarity Threshold", Range(0,1)) = 0.1
		_EmissionStrength ("Emission Strength", Range(0,1)) = 0.5
		[Toggle(_DOUBLE_SIDED_ILLUM)] _DOUBLE_SIDED_ILLUM ("Double Sided Illumination", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull Mode", Float) = 2
    }
	CustomEditor "AnimatedShaderGUI"
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        LOD 200
		
		Pass
		{
			Name "FORWARD"
			Tags 
			{
                "LightMode"="ForwardBase"
            }
			Cull [_Cull]
			
			CGPROGRAM
			#pragma exclude_renderers d3d11 gles
			#pragma only_renderers d3d9 d3d11 glcore gles 
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile_fog
			#pragma shader_feature _DOUBLE_SIDED_ILLUM
			#pragma shader_feature _EMISSION
			#pragma shader_feature _AUTOMATIC
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _EmissionMap;
			float4 _EmissionMap_ST;
			float4 _TimeEditor;
			float4 _EmissionColor;
			float4 _AutoEmisColor;
			float _AutoEmisThres;
			float _EmissionStrength;
			fixed4 _Color;
			float _Cutoff;
			float _Speed;
			float _Cull;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				SHADOW_COORDS(1)
				UNITY_FOG_COORDS(2)
				fixed4 diff : COLOR0;
			};
			
			int getFrame () 
			{
				int frame = 0;
				frame = (int)(fmod(_Time.y * _Speed, (1/_MainTex_ST.x) * (1/_MainTex_ST.y)));
				return frame;
			}
			
			float4 calculateEmission(float4 anim){
				float4 emisColor = _AutoEmisColor;
				float threshold = _AutoEmisThres;
				float3 values = float3(step((abs(float(emisColor.r) - float(anim.r))), threshold), 
					step((abs(float(emisColor.g) - float(anim.g))), threshold), 
					step((abs(float(emisColor.b) - float(anim.b))), threshold));
				float4 emission = float4((anim.r * values.r * values.g * values.b), 
					(anim.g * values.r * values.g * values.b), 
					(anim.b * values.r * values.g * values.b), 1);
				return emission;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				o.pos = UnityObjectToClipPos(v.vertex);
				int frame = getFrame();
				int column = (int)(fmod(frame, (1/_MainTex_ST.x)));
                int row = (int)((-frame) / (1/_MainTex_ST.x));
                float2 offset = float2(column, row);
				o.uv0 =(v.texcoord0 + offset) * (_MainTex_ST.xy);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half nl;
				#ifdef _DOUBLE_SIDED_ILLUM
					half NdotL = dot(worldNormal, _WorldSpaceLightPos0.xyz);
					half INdotL = dot(-worldNormal, _WorldSpaceLightPos0.xyz);
					nl = (NdotL < 0) ? INdotL : NdotL;
				#else
					nl = max(0.0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
				#endif
				o.diff = (nl * _LightColor0);
				TRANSFER_SHADOW(o)
				UNITY_TRANSFER_FOG(o, o.pos)
				return o;
			}
			
			fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{			
				fixed4 c = tex2D(_MainTex, i.uv0) * _Color;
				clip (c.a - _Cutoff);
				fixed3 lighting = i.diff;
				fixed shadow;
				#ifdef _DOUBLE_SIDED_ILLUM
					if (_Cull == 1 && facing > 0)
					{
						shadow = 1;
					}
					else 
					{
						shadow = SHADOW_ATTENUATION(i);
					}
				#else
					if (_Cull == 0 && facing < 0)
					{
						shadow = 1;
					}
					else if (_Cull == 1 && facing > 0)
					{
						shadow = 1;
					}
					else 
					{
						shadow = SHADOW_ATTENUATION(i);
					}
				#endif
				lighting *= shadow;
				lighting += UNITY_LIGHTMODEL_AMBIENT;
				float4 emission = float4(0, 0, 0, 0);
				#ifdef _EMISSION
					#ifdef _AUTOMATIC
						emission = calculateEmission(c);
					#else
						emission = tex2D(_EmissionMap, i.uv0) * _EmissionColor;
					#endif
					emission *= _EmissionStrength;
				#endif
				c.rgb *= lighting;
				c.rgb += emission;
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;			
			}
			ENDCG
		}
		Pass
		{
			Name "FORWARD_ADD"
			Tags 
			{
                "LightMode"="ForwardAdd"
            }
			Cull [_Cull]
			Blend One One
			
			CGPROGRAM
			#pragma exclude_renderers d3d11 gles
			#pragma only_renderers d3d9 d3d11 glcore gles 
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#pragma shader_feature _DOUBLE_SIDED_ILLUM
			#pragma shader_feature DIRECTIONAL_COOKIE
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _TimeEditor;
			fixed4 _Color;
			float _Cutoff;
			float _Speed;
			float _Cull;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord0 : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv0 : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float4 lightPos : TEXCOORD3;
				SHADOW_COORDS(4)
				fixed4 diff : COLOR0;
			};
			
			int getFrame () 
			{
				int frame = 0;
				frame = (int)(fmod(_Time.y * _Speed, (1/_MainTex_ST.x) * (1/_MainTex_ST.y)));
				return frame;
			}
			
			float4 diffuse (v2f i) {
				float3 normalDirection = normalize(i.normalDir);
				float3 lightDirection;
				float attenuation;		 
				if (0.0 == _WorldSpaceLightPos0.w)
				{
					attenuation = 1.0;
					lightDirection = normalize(_WorldSpaceLightPos0.xyz);
				} 
				else
				{
					float3 vertexToLightSource = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
					float distance = length(vertexToLightSource);
					attenuation = 1.0 / distance; 
					lightDirection = normalize(vertexToLightSource);
				}
				
				float3 diffuseReflection;
				#ifdef _DOUBLE_SIDED_ILLUM
					float normalLight = dot(normalDirection, lightDirection);
					float InormalLight = dot(-normalDirection, lightDirection);
					float nl = (normalLight < 0) ? InormalLight : normalLight;
					diffuseReflection = attenuation * _LightColor0.rgb * nl;
				#else
					diffuseReflection = attenuation * _LightColor0.rgb * max(0.0, dot(normalDirection, lightDirection));
				#endif
				float cookieAttenuation = 1.0;
				#ifdef SPOT
					if (0.0 == _WorldSpaceLightPos0.w)
					{
						cookieAttenuation = tex2Dlod(_LightTexture0, float4(i.lightPos.xy, 0, 0)).a;
					}
					else if (1.0 != unity_WorldToLight[3][3]) 
					{
						cookieAttenuation = tex2Dlod(_LightTexture0, float4(i.lightPos.xy / i.lightPos.w + float2(0.5, 0.5), 0, 0)).a;
					}
				#endif
				return float4(cookieAttenuation * diffuseReflection, 1.0);
			}

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				int frame = getFrame();
				int column = (int)(fmod(frame, (1/_MainTex_ST.x)));
                int row = (int)((-frame) / (1/_MainTex_ST.x));
                float2 offset = float2(column, row);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv0 =(v.texcoord0 + offset) * (_MainTex_ST.xy);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				#ifdef SPOT
					o.lightPos = mul(unity_WorldToLight, o.worldPos);
				#endif
				o.normalDir = normalize(mul(float4(v.normal, 0), unity_WorldToObject).xyz);
				o.diff = diffuse(o);
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
			{			
				fixed4 c = tex2D(_MainTex, i.uv0) * _Color;
				clip (c.a - _Cutoff);
				float3 lighting = i.diff;
				fixed shadow;
				#ifdef _DOUBLE_SIDED_ILLUM
					if (_Cull == 1 && facing > 0)
					{
						shadow = 1;
					}
					else 
					{
						shadow = SHADOW_ATTENUATION(i);
					}
				#else
					if (_Cull == 0 && facing < 0)
					{
						shadow = 1;
					}
					else if (_Cull == 1 && facing > 0)
					{
						shadow = 1;
					}
					else 
					{
						shadow = SHADOW_ATTENUATION(i);
					}
				#endif
				lighting *= shadow;
				c.rgb *= lighting;
				return c;			
			}
			ENDCG
		}
	    Pass {
			Name "ShadowCaster"
			Tags 
			{ 
				"LightMode" = "ShadowCaster" 
			}
			Cull [_Cull]

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"

			struct v2f 
			{
				V2F_SHADOW_CASTER;
				float2 uv : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform float4 _MainTex_ST;
			uniform float _Speed;
			
			int getFrame() 
			{
				int frame = 0;
				frame = (int)(fmod(_Time.y * _Speed, (1/_MainTex_ST.x) * (1/_MainTex_ST.y)));
				return frame;
			}

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				int frame = getFrame();
				int column = (int)(fmod(frame, (1/_MainTex_ST.x)));
                int row = (int)((-frame) / (1/_MainTex_ST.x));
                float2 offset = float2(column, row);
				o.uv = (v.texcoord + offset) * (_MainTex_ST.xy);
				return o;
			}

			uniform sampler2D _MainTex;
			uniform fixed _Cutoff;
			uniform fixed4 _Color;

			float4 frag(v2f i, fixed facing : VFACE) : SV_Target
			{
				fixed4 texcol = tex2D( _MainTex, i.uv );
				clip(texcol.a * _Color.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
    FallBack Off
}