using UnityEngine;

[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour {
	
    static int 
	    baseColorId = Shader.PropertyToID("_BaseColor"),
	    cutoffId = Shader.PropertyToID("_Cutoff"),
	    metallicId = Shader.PropertyToID("_Metallic"),
	    smoothnessId = Shader.PropertyToID("_Smoothness"),
	    fresnelID =  Shader.PropertyToID("_Fresnel"),
	    emissionColorId = Shader.PropertyToID("_EmissionColor");
		
    
    [SerializeField]
    Color baseColor = Color.white;
    
    [SerializeField, ColorUsage(false, true)]
    Color emissionColor = Color.black;
    
    [SerializeField, Range(0f, 1f)]
    float alphaCutoff = 0.5f, metallic = 0f, smoothness = 0.5f, fresnel = 1.0f;
    
    static MaterialPropertyBlock block;
    
    void OnValidate () {
	    if (block == null) {
		    block = new MaterialPropertyBlock();
	    }
	    block.SetColor(baseColorId, baseColor);
	    block.SetFloat(cutoffId, alphaCutoff);
	    block.SetFloat(metallicId, metallic);
	    //block.SetFloat(fresnelID, fresnel);
	    block.SetFloat(smoothnessId, smoothness);
	    block.SetColor(emissionColorId, emissionColor);
	    GetComponent<Renderer>().SetPropertyBlock(block);
    }
    
    void Awake () {
	    OnValidate();
    }
    
    
}