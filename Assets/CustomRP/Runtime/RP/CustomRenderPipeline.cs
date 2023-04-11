using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    CameraRenderer renderer = new CameraRenderer();

    //批处理配置
    private bool useDynamicBatching, useGPUInstancing;
    
    public CustomRenderPipeline(bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher)
    {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        //配置SRP Batch
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        
        GraphicsSettings.lightsUseLinearIntensity = true;
    }
    
    protected override void Render (
        ScriptableRenderContext context, Camera[] cameras
    ) {
        foreach (Camera camera in cameras) {
            renderer.Render(context, camera, useDynamicBatching, useGPUInstancing);
        }
    }
}