using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer {

	const string bufferName = "Render Camera";

	static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
	static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");
	
	private static ShaderTagId[] extraShaderTagIds =
	{
		new ShaderTagId("CatSRP/UnlitPro")
	};
	
	CommandBuffer buffer = new CommandBuffer {
		name = bufferName
	};

	ScriptableRenderContext context;

	Camera camera;

	CullingResults cullingResults;

	private Lighting lighting = new Lighting();
	
	public void Render (ScriptableRenderContext context, Camera camera, 
		bool useDynamicBatching, bool useGPUInstancing,
		ShadowSettings shadowSettings) {
		this.context = context;
		this.camera = camera;

		PrepareBuffer();
		PrepareForSceneWindow();
		if (!Cull(shadowSettings.maxDistance)) {
			return;
		}
		
		buffer.BeginSample(SampleName); // nest sampling for shadow
		ExecuteBuffer();
		lighting.Setup(context, cullingResults, shadowSettings);
		buffer.EndSample(SampleName);
		
		Setup();
		DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
		DrawUnsupportedShaders();
		DrawGizmos();
		lighting.Cleanup();
		Submit();
	}

	bool Cull (float maxShadowDistance) {
		if (camera.TryGetCullingParameters(out ScriptableCullingParameters p)) {
			p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
			cullingResults = context.Cull(ref p);
			return true;
		}
		return false;
	}

	void Setup () {
		context.SetupCameraProperties(camera);
		CameraClearFlags flags = camera.clearFlags;
		buffer.ClearRenderTarget(
			flags <= CameraClearFlags.Depth,
			flags == CameraClearFlags.Color,
			flags == CameraClearFlags.Color ?
				camera.backgroundColor.linear : Color.clear
		);
		buffer.BeginSample(SampleName);
		ExecuteBuffer();
	}

	void Submit () {
		buffer.EndSample(SampleName);
		ExecuteBuffer();
		context.Submit();
	}

	void ExecuteBuffer () {
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}

	void DrawVisibleGeometry (bool useDynamicBatching, bool useGPUInstancing) {
		var sortingSettings = new SortingSettings(camera) {
			criteria = SortingCriteria.CommonOpaque
		};
		
		//unlit
		var drawingSettings = new DrawingSettings(
			unlitShaderTagId, sortingSettings
		)
		{
			enableDynamicBatching = useDynamicBatching,
			enableInstancing = useGPUInstancing,
			perObjectData = PerObjectData.Lightmaps |
			                PerObjectData.ShadowMask |
			                PerObjectData.LightProbe |
			                PerObjectData.LightProbeProxyVolume 
		};
		//extraShader
		for (int i = 0; i < extraShaderTagIds.Length; i++) {
			drawingSettings.SetShaderPassName(i+1, extraShaderTagIds[i]);
		}
		
		//lit
		drawingSettings.SetShaderPassName(extraShaderTagIds.Length+1, litShaderTagId);
		
		var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);

		context.DrawRenderers(
			cullingResults, ref drawingSettings, ref filteringSettings
		);

		context.DrawSkybox(camera);

		sortingSettings.criteria = SortingCriteria.CommonTransparent;
		drawingSettings.sortingSettings = sortingSettings;
		filteringSettings.renderQueueRange = RenderQueueRange.transparent;

		context.DrawRenderers(
			cullingResults, ref drawingSettings, ref filteringSettings
		);
	}
}