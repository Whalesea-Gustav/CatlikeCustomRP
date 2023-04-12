using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "CatSRP/CustomRenderPipelineAsset")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{
    [SerializeField] 
    private bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;
    [SerializeField]
    ShadowSettings shadows = default;
    protected override RenderPipeline CreatePipeline()
    {
        return new CustomRenderPipeline(useDynamicBatching, useGPUInstancing, useSRPBatcher, shadows);
    }
}