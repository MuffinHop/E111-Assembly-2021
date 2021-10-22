using System;
using UnityEngine;
using UnityEngine.Serialization;

public class RenderEverything : MonoBehaviour
{
    [SerializeField] private Material _pass_A;
    [SerializeField] private Material _pass_B;
    [SerializeField] private Material _pass_C;
    [SerializeField] private Material _pass_D;
    [SerializeField] private Material _pass_FXAA;
    private CustomRenderTexture _rt_A, _rt_B, _rt_C, _rt_D;
    private int screenWidth;
    private int screenHeight;

    private void Start()
    {
        screenWidth = Screen.width;
        screenHeight = Screen.height;
        _rt_A = new CustomRenderTexture(screenWidth, (int)(screenHeight * 0.666f), RenderTextureFormat.ARGBHalf);
        _rt_B = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
        _rt_C = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
        _rt_D = new CustomRenderTexture(screenWidth, screenHeight, RenderTextureFormat.ARGBHalf);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination){
        
        Graphics.Blit(source, _rt_A, _pass_A);
        Graphics.Blit(null, _rt_B, _pass_B);
        Graphics.Blit(null, _rt_C, _pass_C);
        Graphics.Blit(null, _rt_D, _pass_D);
        Graphics.Blit(null, destination, _pass_FXAA);
    }
}
