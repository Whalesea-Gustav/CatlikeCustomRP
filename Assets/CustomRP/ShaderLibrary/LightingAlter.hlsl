//用来存放计算光照相关的方法
//HLSL编译保护机制
#ifndef CUSTOM_LIGHTING_ALTER_INCLUDE
#define CUSTOM_LIGHTING_ALTER_INCLUDE

//第一次写的时候这里的Surface会标红，因为只看这一个hlsl文件，我们并未定义Surface
//但在include到整个Lit.shader中后，编译会正常，至于IDE还标不标红就看IDE造化了...
//另外，我们需要在include该文件之前include Surface.hlsl，因为依赖关系
//所有的include操作都放在LitPass.hlsl中
//计算物体表面接收到的光能量
float3 IncomingLight(Surface surface,Light light)
{
    return saturate(dot(surface.normal,light.direction)) * light.attenuation * light.color;
}

//新增的GetLighting方法，传入surface和light，返回真正的光照计算结果，即物体表面最终反射出的RGB光能量
float3 GetLighting(Surface surface,Light light)
{
    return IncomingLight(surface,light) * surface.color;
}

float3 GetLighting (Surface surface, BRDF brdf, Light light) {
    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

//GetLighting返回光照结果，这个GetLighting只传入一个surface
float3 GetLighting (Surface surface) {
    ShadowData shadowData = GetShadowData(surface);
    float3 color = 0.0;
    for (int i = 0; i < GetDirectionalLightCount(); i++) {
        color += GetLighting(surface, GetDirectionalLight(i, surface, shadowData));
    }
    return color;
}

float3 GetLighting (Surface surface, BRDF brdf) {
    ShadowData shadowData = GetShadowData(surface);
    float3 color = 0.0;
    for (int i = 0; i < GetDirectionalLightCount(); i++) {
        color += GetLighting(surface, brdf, GetDirectionalLight(i, surface, shadowData));
    }
    
    for (int j = 0; j < GetOtherLightCount(); j++) {
        Light light = GetOtherLight(j, surface, shadowData);
        color += GetLighting(surface, brdf, light);
    }
    
    return color;
}


float3 GetLighting (Surface surface, BRDF brdf, GI gi) {
    ShadowData shadowData = GetShadowData(surface);
    shadowData.shadowMask = gi.shadowMask;
    //return gi.shadowMask.shadows.rgb;
    float3 color = IndirectBRDF(surface, brdf, gi.diffuse, gi.specular);
    for (int i = 0; i < GetDirectionalLightCount(); i++) {
        color += GetLighting(surface, brdf, GetDirectionalLight(i, surface, shadowData));
    }

    #if defined(_LIGHTS_PER_OBJECT)
    for (int j = 0; j < min(unity_LightData.y, 8); j++) {
        int lightIndex = unity_LightIndices[(uint)j / 4][(uint) j % 4];
        Light light = GetOtherLight(lightIndex, surface, shadowData);
        color += GetLighting(surface, brdf, light);
    }
    #else
    for (int j = 0; j < GetOtherLightCount(); j++) {
        Light light = GetOtherLight(j, surface, shadowData);
        color += GetLighting(surface, brdf, light);
    }
    #endif
        
    return color;
}


#endif