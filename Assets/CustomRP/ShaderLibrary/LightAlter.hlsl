//用来定义光源属性
#ifndef CUSTOM_LIGHT_ALTER_INCLUDED
#define CUSTOM_LIGHT_ALTER_INCLUDED

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_CustomLight)
    //float4 _DirectionalLightColor;
    //float4 _DirectionalLightDirection;
    int _DirectionalLightCount;
    float4 _DirectionalLightColors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightDirections[MAX_DIRECTIONAL_LIGHT_COUNT];
    float4 _DirectionalLightShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct Light
{
    //光源颜色
    float3 color;
    //光源方向：指向光源
    float3 direction;

    float attenuation;
};

int GetDirectionalLightCount () {
    return _DirectionalLightCount;
}

DirectionalShadowData GetDirectionalShadowData(int lightIndex)
{
    DirectionalShadowData data;
    //阴影强度
    data.strength = _DirectionalLightShadowData[lightIndex].x;
    //Tile索引
    data.tileIndex = _DirectionalLightShadowData[lightIndex].y;
    return data;
}

Light GetDirectionalLight (int index, Surface surfaceWS) {
    Light light;
    light.color = _DirectionalLightColors[index].rgb;
    light.direction = _DirectionalLightDirections[index].xyz;

    DirectionalShadowData shadowData = GetDirectionalShadowData(index);
    light.attenuation = GetDirectionalShadowAttenuation(shadowData, surfaceWS);
    
    return light;
}

#endif