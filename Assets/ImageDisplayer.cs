using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.IO;

[Serializable]
public class ImageData
{
    public int Id;
    public String Filename;
}
public class ImageDisplayer : MonoBehaviour
{
    void Start()
    {
        string path = Application.streamingAssetsPath + "\\images.json";
        string JSONstring = File.ReadAllText(path);
        var myObject = JsonUtility.FromJson<ImageData>(JSONstring);
    }
}
