using System;
using UnityEngine;
using UnityEngine.Serialization;

public class RenderEverything : MonoBehaviour
{
    private static readonly int IChannel0 = Shader.PropertyToID("iChannel0");
    private static readonly int IFrame = Shader.PropertyToID("iFrame");
    private static readonly int IDeltaTime = Shader.PropertyToID("iDeltaTime");
    private static readonly int ITime = Shader.PropertyToID("iTime");
    private static readonly int IChannel0Resolution = Shader.PropertyToID("iChannel0Resolution");
    [SerializeField] private Material _pass_A;
    [SerializeField] private Material _pass_B;
    [SerializeField] private Material _pass_C;
    [SerializeField] private Material _pass_D;
    [SerializeField] private Material _pass_FXAA;
    [SerializeField] private CustomRenderTexture _rt_A, _rt_B, _rt_C, _rt_D;
    private int screenWidth;
    private int screenHeight;

    private void InitCRT(CustomRenderTexture texture)
    {
        texture.depth = 0;
        texture.filterMode = FilterMode.Bilinear;
        texture.format = RenderTextureFormat.ARGBHalf;

        if (!texture.IsCreated())
        {
            texture.Create();
        }

        texture.Initialize();
        
    }
    private void Start()
    {
        screenWidth = Screen.width;
        screenHeight = Screen.height;
        _rt_A = new CustomRenderTexture(screenWidth, (int)(screenHeight * 0.666f), RenderTextureFormat.ARGBHalf);
        _rt_B = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
        _rt_C = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
        _rt_D = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
        InitCRT(_rt_A);
        InitCRT(_rt_B);
        InitCRT(_rt_C);
        InitCRT(_rt_D);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination){
        // A
        _pass_A.SetTexture(IChannel0, _rt_A);
        _pass_A.SetVector(IChannel0Resolution, new Vector4(_rt_A.width, _rt_A.height, 0f, 0f));
        _pass_A.SetVector("iResolution", new Vector4(
            _rt_A.width, _rt_A.height,
            0f,
            0f
        ));
        // B
        _pass_B.SetVector("iResolution", new Vector4(
            _rt_B.width, _rt_B.height,
            0f,
            0f
        ));
        // C
        _pass_C.SetVector("iResolution", new Vector4(
            _rt_C.width, _rt_C.height,
            0f,
            0f
        ));
        // D
        _pass_D.SetVector("iResolution", new Vector4(
            _rt_D.width, _rt_D.height,
            0f,
            0f
        ));
        // FXAA
        _pass_FXAA.SetVector("iResolution", new Vector4(
            Screen.width, Screen.height,
            0f,
            0f
        ));
        Graphics.Blit(source, _rt_A, _pass_A);
        _pass_B.SetTexture(IChannel0, _rt_A);
        _pass_B.SetVector(IChannel0Resolution, new Vector4(_rt_A.width, _rt_A.height, 0f, 0f));
        Graphics.Blit(null, _rt_B, _pass_B);
        _pass_C.SetTexture(IChannel0, _rt_B);
        _pass_C.SetVector(IChannel0Resolution, new Vector4(_rt_B.width, _rt_B.height, 0f, 0f));
        Graphics.Blit(null, _rt_C, _pass_C);
        _pass_D.SetTexture(IChannel0, _rt_C);
        _pass_D.SetVector(IChannel0Resolution, new Vector4(_rt_C.width, _rt_C.height, 0f, 0f));
        Graphics.Blit(null, _rt_D, _pass_D);
        _pass_FXAA.SetTexture(IChannel0, _rt_D);
        _pass_FXAA.SetVector(IChannel0Resolution, new Vector4(_rt_D.width, _rt_D.height, 0f, 0f));
        Graphics.Blit(null, destination, _pass_FXAA);
    }
}
