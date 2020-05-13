Shader "Screen Space Decal/Unlit Decal" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Cutout ("Cutout", float) = 0.5
    }
    SubShader {
        Tags {  "Queue"="AlphaTest+1" "RenderType"="TransparentCutout" }
        LOD 100
        Cull Front
        ZWrite Off
        ZTest Greater

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 projPos   : TEXCOORD0;
                float3 ray       : TEXCOORD1;
                float4x4 invMV   : TEXCOORD2;
                UNITY_FOG_COORDS(6)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _CameraDepthTexture;
            half4 _Color;
            half _Cutout;

            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos (o.pos);
                o.ray = UnityObjectToViewPos(v.vertex) * float3(-1,-1,1);
                o.invMV = mul(unity_WorldToObject, unity_CameraToWorld);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            half4 frag (v2f i) : SV_Target {
                i.ray = i.ray * (_ProjectionParams.z / i.ray.z);
                float depth = Linear01Depth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                float4 viewPos = float4(i.ray * depth,1);
                // float3 worldPos = mul (unity_CameraToWorld, viewPos).xyz;
                // float4 localPos = mul(unity_WorldToObject, float4(worldPos,1));
                float4x4 invMV = i.invMV;
                float4 localPos = mul(invMV, viewPos);
                localPos.xyz /= localPos.w;
                clip(0.5f - abs(localPos.xyz));

                float2 uv = localPos.xy + 0.5f;
                uv = TRANSFORM_TEX(uv, _MainTex);

                half4 c = tex2D(_MainTex, uv);
                clip(c.a * _Color.a - _Cutout);

                c.rgb *= _Color.rgb;
                UNITY_APPLY_FOG(i.fogCoord, c);
                return c;
            }
            ENDCG
        }
    }
}
