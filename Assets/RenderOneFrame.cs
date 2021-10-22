using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderOneFrame : MonoBehaviour
{
    [SerializeField] private GameObject go;
    void Update()
    {
        if (go.activeSelf == false && Time.time>2.2f)
        {
            go.SetActive(true);
        }
    }
}
