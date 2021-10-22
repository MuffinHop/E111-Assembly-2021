using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FPSreport : MonoBehaviour
{
    [SerializeField] private Text textCanvas;

    void Update()
    {
        int value = (int)(1.0f / Time.smoothDeltaTime);
        textCanvas.text = value.ToString() + " FPS";
    }
}
