using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    CameraRenderer renderer = new CameraRenderer();

    //batch
    private bool useDynamicBatching, useGPUInstancing;

    //Shadow
    ShadowSettings shadowSettings;

    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher,
        ShadowSettings shadowSettings)
    {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        //配置SRP Batch
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        
        GraphicsSettings.lightsUseLinearIntensity = true;

        this.shadowSettings = shadowSettings;
    }
    
    protected override void Render (
        ScriptableRenderContext context, Camera[] cameras
    ) {
        foreach (Camera camera in cameras) {
            renderer.Render(context, camera, useDynamicBatching, useGPUInstancing, shadowSettings);
        }
    }
}