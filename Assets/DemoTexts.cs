using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DemoTexts : MonoBehaviour
{
    [SerializeField] private String[] texts;
    [SerializeField] private Text textCanvas;
    [SerializeField] private DeviceController _deviceController;
    [SerializeField] private AudioSource _audioSource;
    [SerializeField] private float _BPM;
    [SerializeField] private Canvas _canvas;
    private int rpb = 8; /* rows per beat */
    private float row_rate;
    void Update()
    {
        float row = DrawToRenderTexture.ROWI;
        int text_index = (int) _deviceController.Device.GetTrack("word_index").GetValue(row);
        int word_length = (int) _deviceController.Device.GetTrack("word_length").GetValue(row);
        String text = texts[text_index % texts.Length];
        word_length = Mathf.Min(word_length, text.Length);
        if (word_length <= 0) {
        
            textCanvas.enabled = false;
            //_canvas.transform.gameObject.SetActive(false);
        }
        else
        {
            //_canvas.transform.gameObject.SetActive(true);
            textCanvas.enabled = true;
        }
        if (word_length >= 0)
        {
            textCanvas.text = text.Substring(0, word_length).ToLower();
        }
        else
        {
            textCanvas.text = text.Substring(Mathf.Abs(word_length) % text.Length, (int) Mathf.Max(text.Length + word_length,0f)).ToLower();
        }

        textCanvas.rectTransform.anchoredPosition = new Vector3(
            _deviceController.Device.GetTrack("FontPositionX").GetValue(row) + (word_length < 1f ? 100000f : 0f),
            _deviceController.Device.GetTrack("FontPositionY").GetValue(row) + (word_length < 1f ? 100000f : 0f),
            0f);
        textCanvas.color = new Color(
            _deviceController.Device.GetTrack("FontColorR").GetValue(row),
            _deviceController.Device.GetTrack("FontColorG").GetValue(row),
            _deviceController.Device.GetTrack("FontColorB").GetValue(row));
        textCanvas.fontSize = (int) _deviceController.Device.GetTrack("FontSize").GetValue(row);
    }
}
