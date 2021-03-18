Shader "Custom/LiquidShader"
{
	Properties
	{
		_MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,0.4)
		_FresnelColor("Fresnel Color", Color) = (1,1,1,1)
		_FresnelBias("Fresnel Bias", Float) = 0
		_FresnelScale("Fresnel Scale", Float) = 1
		_FresnelPower("Fresnel Power", Float) = 1
		_BumpMap("Normal Map", 2D) = "Bump" {}
		_Shininess("Shininess", Float) = 10
		_SpecColor("Specual Material Color", Color) = (1, 1, 1, 1)
		_FlowSpeed("Flow Speed", float) = 1
		_MaxHeight("Displacement Height", float) = 1
		//_FlowDirection("Flor Direction", )
	}

		SubShader
		{
			 Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		Cull front

			Pass
			{
				CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed4 _Color;
		fixed4 _FresnelColor;
		fixed _FresnelBias;
		fixed _FresnelScale;
		fixed _FresnelPower;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		float4 _SpecColor;
		float _Shininess;
		float _FlowSpeed;
		uniform float _MaxHeight;

		struct appdata_t
		{
			float4 pos : POSITION;
			float2 uv : TEXCOORD0;
			half3 normal : NORMAL;
			float4 texcoord : TEXCOORD1;
			float2 bumpUv : TEXCOORD2;

		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			float fresnel : TEXCOORD1;
			float3 normal : NORMAL;
			float4 worldPos : TEXCOORD2;
			float4 colors : COLOR;
			half2 bumpUv : TEXCOORD3;
		};

float2 FlowUV(float2 uv, float time) {
	return uv + time;
}

		v2f vert(appdata_t v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.pos);
			float2 uv = FlowUV(v.uv, _Time.y / _FlowSpeed);
			float2 bumpUv = FlowUV(v.bumpUv, _Time.y / _FlowSpeed);

			o.uv = TRANSFORM_TEX(uv, _MainTex);
			o.bumpUv = TRANSFORM_TEX(bumpUv, _BumpMap);

			float3 i = normalize(ObjSpaceViewDir(v.pos));

			o.fresnel = _FresnelBias + _FresnelScale * pow(1 + dot(i, v.normal), _FresnelPower);

			float4 bumpColor = tex2Dlod(_BumpMap, v.texcoord);
			float df = 0.30 * bumpColor.x + 0.59 * bumpColor.y + 0.11 * bumpColor.z;

			float4 displacement = float4(v.normal * df * _MaxHeight , 0.0) + v.pos;

			o.pos = UnityObjectToClipPos(v.pos + displacement);
			o.colors = bumpColor;

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
		fixed4 c = (tex2D(_MainTex, i.bumpUv) * _Color) - (tex2D(_MainTex, i.uv) * _Color.x) * _SpecColor.x * _Shininess;
return lerp(c, _FresnelColor, 1 - i.fresnel);
		}
				 ENDCG
			 }

		}

}