using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShowVisy : MonoBehaviour
{
    [SerializeField] private DeviceController _deviceController;

    [SerializeField] private GameObject _visy;

    void Update()
    {
        float row = DrawToRenderTexture.ROWI;
        int show = (int) _deviceController.Device.GetTrack("visy_overlay").GetValue(row);
        if (show >= 1)
        {
            _visy.SetActive(true);
        }
        else
        {
            _visy.SetActive(false);
        }
    }
}
