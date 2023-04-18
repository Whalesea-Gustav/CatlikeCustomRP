#ifndef CUSTOM_UNLIT_PASS_INCLUDED
#define CUSTOM_UNLIT_PASS_INCLUDED

#include "../ShaderLibrary/Surface.hlsl"
#include "../ShaderLibrary/ShadowsAlter.hlsl"
#include "../ShaderLibrary/LightAlter.hlsl"
#include "../ShaderLibrary/BRDF.hlsl"
#include "../ShaderLibrary/GIAlter.hlsl"
#include "../ShaderLibrary/LightingAlter.hlsl"

//使用Core RP Library的CBUFFER宏指令包裹材质属性，让Shader支持SRP Batcher，同时在不支持SRP Batcher的平台自动关闭它。
//CBUFFER_START后要加一个参数，参数表示该C buffer的名字(Unity内置了一些名字，如UnityPerMaterial，UnityPerDraw。
// CBUFFER_START(UnityPerMaterial)
// float4 _BaseColor;
// CBUFFER_END


//使用结构体定义顶点着色器的输入，一个是为了代码更整洁，一个是为了支持GPU Instancing（获取object的index）
struct Attributes
{
    float3 positionOS:POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 baseUV:TEXCOORD0;
    GI_ATTRIBUTE_DATA
    
    //定义GPU Instancing使用的每个实例的ID，告诉GPU当前绘制的是哪个Object
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
//为了在片元着色器中获取实例ID，给顶点着色器的输出（即片元着色器的输入）也定义一个结构体
//命名为Varings是因为它包含的数据可以在同一三角形的片段之间变化
struct Varyings
{
    float4 positionCS:SV_POSITION;
    float3 positionWS : VAR_POSITION;
    float3 normalWS : VAR_NORMAL;
    float4 tangentWS : VAR_TANGENT;
    float2 baseUV:VAR_BASE_UV;
    float2 detailUV : VAR_DETAIL_UV;
    GI_VARYINGS_DATA
    
    //定义每一个片元对应的object的唯一ID
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

Varyings LitPassVertex(Attributes input)
{
    Varyings output;
    //从input中提取实例的ID并将其存储在其他实例化宏所依赖的全局静态变量中
    UNITY_SETUP_INSTANCE_ID(input);
    //将实例ID传递给output
    UNITY_TRANSFER_INSTANCE_ID(input,output);
    TRANSFER_GI_DATA(input, output);
    
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    output.positionWS = positionWS;
    output.positionCS = TransformWorldToHClip(positionWS);

    #if UNITY_REVERSED_Z
    output.positionCS.z =
        min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    output.positionCS.z =
        max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.tangentWS =
        float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_BaseMap_ST);
    output.baseUV = TransformBaseUV(input.baseUV);
    output.detailUV = TransformDetailUV(input.baseUV);
    return output;
}

float4 LitPassFragment(Varyings input) : SV_TARGET
{
    //从input中提取实例的ID并将其存储在其他实例化宏所依赖的全局静态变量中
    UNITY_SETUP_INSTANCE_ID(input);
    ClipLOD(input.positionCS.xy, unity_LODFade.x);
    
    float4 base = GetBase(input.baseUV, input.detailUV);
    
    #if defined(_CLIPPING)
        clip(base.a - GetCutoff(input.baseUV));
    #endif

    //在片元着色器中构建Surface结构体，即物体表面属性，构建完成之后就可以在片元着色器中计算光照
    Surface surface;
    surface.position = input.positionWS;
    surface.normal = NormalTangentToWorld(
        GetNormalTS(input.baseUV), input.normalWS, input.tangentWS
    );
    surface.interpolatedNormal = normalize(input.normalWS);
    surface.viewDirection = normalize(_WorldSpaceCameraPos - input.positionWS);
    surface.depth = -TransformWorldToView(input.positionWS).z;
    surface.color = base.rgb;
    surface.alpha = base.a;

    surface.metallic = GetMetallic(input.baseUV);
    surface.smoothness = GetSmoothness(input.baseUV, input.detailUV);
    surface.fresnelStrength = GetFresnel(input.baseUV);
    surface.dither = InterleavedGradientNoise(input.positionCS.xy, 0);
    surface.occlusion = 1.0;
    #if defined(_PREMULTIPLY_ALPHA)
        BRDF brdf = GetBRDF(surface, true);
    #else
        BRDF brdf = GetBRDF(surface);
    #endif

    GI gi = GetGI(GI_FRAGMENT_DATA(input), surface, brdf);
    surface.color = GetLighting(surface, brdf, gi);
    surface.color += GetEmission(input.baseUV);
    return float4(surface.color,surface.alpha);
}

#endif