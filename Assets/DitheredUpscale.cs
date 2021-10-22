using System;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

//[ExecuteAlways]
public class DitheredUpscale : MonoBehaviour
{
    private static readonly int IChannel0 = Shader.PropertyToID("iChannel0");
    private static readonly int IFrame = Shader.PropertyToID("iFrame");
    private static readonly int IDeltaTime = Shader.PropertyToID("iDeltaTime");
    private static readonly int ITime = Shader.PropertyToID("iTime");
    private static readonly int IChannel0Resolution = Shader.PropertyToID("iChannel0Resolution");
    [SerializeField] private CustomRenderTexture _rTex;
    [SerializeField] private Material _material;
    [SerializeField] private bool fullRes;
    [SerializeField] private DrawToRenderTexture _drawToRenderTexture;
    [SerializeField] private MeshRenderer _meshRenderer;
    void Start()
    {
        if (!_rTex)
        {
            Debug.LogError("A texture or a render texture are missing, assign them.");
        }

        if( _rTex != null )
        {
            _rTex.DiscardContents(true, true);
            _rTex.Release();
            _rTex = null;
        }

        if (fullRes)
        {
            _rTex = new CustomRenderTexture(Screen.width, Screen.height,  RenderTextureFormat.ARGBFloat);
        }
        else
        {
            _rTex = new CustomRenderTexture(Screen.width/2, Screen.height/2, RenderTextureFormat.ARGBFloat);
        }

        _rTex.filterMode = FilterMode.Point;
        _rTex.depth = 0;
        _rTex.format = RenderTextureFormat.ARGBFloat;
        _rTex.material = _material;
        _rTex.updateMode = CustomRenderTextureUpdateMode.OnDemand;
        _rTex.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
 
        if( !_rTex.IsCreated() )
            _rTex.Create();
        _rTex.Initialize();
        _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
        _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
        _rTex.initializationMode = CustomRenderTextureUpdateMode.Realtime;
        _rTex.initializationSource = CustomRenderTextureInitializationSource.Material;
        _rTex.initializationMaterial = _material;
        _rTex.material = _material;
        Application.targetFrameRate = 60;
    }
    public static Texture2D Resize(CustomRenderTexture source, int newWidth, int newHeight)
    {
        source.filterMode = FilterMode.Point;
        RenderTexture rt = RenderTexture.GetTemporary(newWidth, newHeight);
        rt.filterMode = FilterMode.Point;
        RenderTexture.active = rt;
        Graphics.Blit(source, rt);
        Texture2D nTex = new Texture2D(newWidth, newHeight);
        nTex.ReadPixels(new Rect(0, 0, newWidth, newHeight), 0,0);
        nTex.Apply();
        RenderTexture.active = null;
        RenderTexture.ReleaseTemporary(rt);
        return nTex;
    }

    private bool later;
    private void Update()
    {
        later = false;
    }

    private int frame = 0;
    [SerializeField] private Texture2D previousTexture;

    private void LateUpdate()
    {
        _rTex.filterMode = FilterMode.Point;
        if (!fullRes)
        {
            if (Input.GetKeyUp(KeyCode.F1))
            {
                _rTex.DiscardContents(true, true);
                _rTex.Release();
                _rTex = null;
                _rTex = new CustomRenderTexture((int) (Screen.width*0.6666f), (int) (Screen.height*0.6666f), RenderTextureFormat.ARGBFloat);

                _rTex.depth = 0;
                _rTex.format = RenderTextureFormat.ARGBFloat;
                _rTex.material = _material;
                _rTex.updateMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.Create();
                _rTex.Initialize();
                _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationSource = CustomRenderTextureInitializationSource.Material;
                _rTex.initializationMaterial = _material;
                _rTex.material = _material;
            } else if (Input.GetKeyUp(KeyCode.F2))
            {
                _rTex.DiscardContents(true, true);
                _rTex.Release();
                _rTex = null;
                _rTex = new CustomRenderTexture((int) (Screen.width*0.7777f), (int) (Screen.height*0.7777f),  RenderTextureFormat.ARGBFloat);
        
                _rTex.depth = 0;
                _rTex.format = RenderTextureFormat.ARGBFloat;
                _rTex.material = _material;
                _rTex.updateMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.Create();
                _rTex.Initialize();
                _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationSource = CustomRenderTextureInitializationSource.Material;
                _rTex.initializationMaterial = _material;
                _rTex.material = _material;
            } else if (Input.GetKeyUp(KeyCode.F3))
            {
                _rTex.DiscardContents(true, true);
                _rTex.Release();
                _rTex = null;
                _rTex = new CustomRenderTexture((int) (Screen.width*0.8888f), (int) (Screen.height*0.8888f), RenderTextureFormat.ARGBFloat);
        
                _rTex.depth = 0;
                _rTex.format = RenderTextureFormat.ARGBFloat;
                _rTex.material = _material;
                _rTex.updateMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.Create();
                _rTex.Initialize();
                _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationSource = CustomRenderTextureInitializationSource.Material;
                _rTex.initializationMaterial = _material;
                _rTex.material = _material;
            } else if (Input.GetKeyUp(KeyCode.F4))
            {
                _rTex.DiscardContents(true, true);
                _rTex.Release();
                _rTex = null;
                _rTex = new CustomRenderTexture(Screen.width, Screen.height, RenderTextureFormat.ARGBFloat);
        
                _rTex.depth = 0;
                _rTex.format = RenderTextureFormat.ARGBFloat;
                _rTex.material = _material;
                _rTex.updateMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.OnDemand;
                _rTex.Create();
                _rTex.Initialize();
                _rTex.updateMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationMode = CustomRenderTextureUpdateMode.Realtime;
                _rTex.initializationSource = CustomRenderTextureInitializationSource.Material;
                _rTex.initializationMaterial = _material;
                _rTex.material = _material;
            } 
        }


        _rTex.material = _material;
        
        
            _material.SetTexture(IChannel0, _drawToRenderTexture.GetRT());
            _material.SetVector(IChannel0Resolution, new Vector4(_drawToRenderTexture.GetRT().width, _drawToRenderTexture.GetRT().height, 0f, 0f));
            if(previousTexture == null)
                previousTexture = new Texture2D(_drawToRenderTexture.GetRT().width, _drawToRenderTexture.GetRT().height);
 
            Rect rectReadPicture = new Rect(0, 0, previousTexture.width, previousTexture.height);
 
            RenderTexture.active = _drawToRenderTexture.GetRT();
 
            // Read pixels
            previousTexture.ReadPixels(rectReadPicture, 0, 0);
            previousTexture.Apply();
 
            RenderTexture.active = null;
            _material.SetTexture("iChannel1", previousTexture);
        

        _material.SetVector("iResolution", new Vector4(
            _rTex.width, _rTex.height,
            0f,
            0f
        ));
        _material.SetInt(IFrame,frame++);
        _material.SetFloat(IDeltaTime,Time.deltaTime);


        if (_meshRenderer != null)
        {
            _meshRenderer.material.mainTexture = _rTex;
        }
        _rTex.Update();

    }

    public CustomRenderTexture GetRT()
    {
        return _rTex;
    }
}