using System;
using RocketNet;
using UnityEngine;

public class DeviceController : MonoBehaviour
{
    [HideInInspector] public Device Device;
    [SerializeField] public bool RecordVideo = false;
    void Start()
    {
        Device = new Device("asm", true);
        if (!Device.player)
        {
            bool connected = Device.Connect();
            while (!connected)
            {
                connected = Device.Connect();
            }
        }
    }

    private void Update()
    {
        if (Input.GetKeyUp(KeyCode.F12))
        {
            bool connected = Device.Connect();
            while (!connected)
            {
                connected = Device.Connect();
            }
        }
    }
}
