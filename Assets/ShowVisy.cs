using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowVisy : MonoBehaviour
{
    [SerializeField] private DeviceController _deviceController;

    [SerializeField] private MeshRenderer _meshRenderer;

    void Update()
    {
        float row = DrawToRenderTexture.ROWI;
        int show = (int) _deviceController.Device.GetTrack("visy_overlay").GetValue(row);
        if (show == 1)
        {
            _meshRenderer.enabled = true;
        }
        else
        {
            _meshRenderer.enabled = false;
        }
    }
}
