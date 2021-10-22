using System;
using System.Collections.Generic;
using UnityEngine;
using Object = System.Object;

//[ExecuteAlways]
public class RenderHistory
{
    public bool FAST_MARCH;
    public bool BUNNY_ON;
    public bool JULIA_ON;
    public bool SURFACE_ON;
    public bool SURFACE_HIGH;
    public bool SKYBOX_ON;
    public bool WORM_ON;
    public bool LIGHTS;

    public override String ToString()
    {
        return
            "FAST_MARCH " + FAST_MARCH + "\n" +
            "BUNNY_ON " + BUNNY_ON + "\n" +
            "JULIA_ON " + JULIA_ON + "\n" +
            "SURFACE_ON " + SURFACE_ON + "\n" +
            "SURFACE_HIGH " + SURFACE_HIGH + "\n" +
            "SKYBOX_ON " + SKYBOX_ON + "\n" +
            "WORM_ON " + WORM_ON + "\n" +
            "LIGHTS " + LIGHTS + "\n";
    }
    public override bool Equals(Object obj)
    {
        //Check for null and compare run-time types.
        if ((obj == null) || ! this.GetType().Equals(obj.GetType()))
        {
            return false;
        }
        else {
            RenderHistory p = (RenderHistory) obj;
            return (FAST_MARCH == p.FAST_MARCH) && (BUNNY_ON == p.BUNNY_ON) && (JULIA_ON == p.JULIA_ON) && (SURFACE_ON == p.SURFACE_ON) && (SKYBOX_ON == p.SKYBOX_ON) && (WORM_ON == p.WORM_ON) && (LIGHTS == p.LIGHTS);
        }
    }
}
public class DrawToRenderTexture : MonoBehaviour
{
    private static readonly int IChannel0 = Shader.PropertyToID("iChannel0");
    private static readonly int IFrame = Shader.PropertyToID("iFrame");
    private static readonly int IDeltaTime = Shader.PropertyToID("iDeltaTime");
    private static readonly int ITime = Shader.PropertyToID("iTime");
    private static readonly int IChannel0Resolution = Shader.PropertyToID("iChannel0Resolution");
    private static readonly int RotationPhase = Shader.PropertyToID("rotationPhase");
    private static readonly int LightColor = Shader.PropertyToID("lightColor");
    private static readonly int LightDirection = Shader.PropertyToID("lightDirection");
    private static readonly int PrevCameraRotation = Shader.PropertyToID("prevCameraRotation");
    private static readonly int PrevCameraPosition = Shader.PropertyToID("prevCameraPosition");
    private static readonly int CameraRotation = Shader.PropertyToID("cameraRotation");
    private static readonly int CameraPosition = Shader.PropertyToID("cameraPosition");
    private static readonly int JuliaOffset = Shader.PropertyToID("juliaOffset");
    private static readonly int BunnyPosition = Shader.PropertyToID("bunnyPosition");
    private static readonly int FogDistance = Shader.PropertyToID("fogDistance");
    private static readonly int FogStrength = Shader.PropertyToID("fogStrength");
    private static readonly int BunAnimation = Shader.PropertyToID("bunAnimation");
    private static readonly int GroundLevel = Shader.PropertyToID("groundLevel");
    private static readonly int MotionBlur = Shader.PropertyToID("motionBlur");
    private static readonly int JuliaRotation = Shader.PropertyToID("juliaRotation");
    private static readonly int JuliaPosition = Shader.PropertyToID("juliaPosition");
    private static readonly int BulbSize = Shader.PropertyToID("bulbSize");
    private static readonly int BulbColor = Shader.PropertyToID("bulbColor");
    private static readonly int BulbPosition = Shader.PropertyToID("bulbPosition");
    private static readonly int BackgroundLight = Shader.PropertyToID("backgroundLight");
    private static readonly int ScatterLightColor = Shader.PropertyToID("scatterLightColor");
    //[SerializeField] private CustomRenderTexture _rTex;
    [SerializeField] private Material _material;
    [SerializeField] public AudioSource _audioSource;
    [SerializeField] private DeviceController _deviceController;
    [SerializeField] private bool fullRes;
    //[SerializeField] private DrawToRenderTexture _drawToRenderTexture;
    [SerializeField] private float _BPM;
    [SerializeField] private Texture2D _skybox;
    private int rpb = 8; /* rows per beat */
    private float row_rate;
    //[SerializeField] private MeshRenderer _meshRenderer;
    private bool deviceProp = false;
    private float pauseCooldown;
    private float prevFrameRow;
    public static float ROWI;
    [SerializeField] private ShaderVariantCollection _collection;
    [SerializeField] private MeshRenderer _loading;
    //private int screenWidth;
    //private int screenHeight;
    private List<RenderHistory> renderHistories = new List<RenderHistory>();
    private String GPU_name;
    void Start()
    {
        row_rate = (float) ((_BPM / 60.0) * rpb);
        Cursor.visible = false;
    }

    private bool hasBeenSetup = false;
    void Setup()
    {

        if (_deviceController != null)
        {
            if (!_deviceController.Device.player)
                _audioSource.Pause();
            else
                _audioSource.Play();
        }
        if(_skybox != null) 
            _material.SetTexture("_MainTex", _skybox);
        if (_collection != null)
        {
            _collection.WarmUp();
        }

        if (_loading != null)
        {
            _loading.enabled = false;
        }
    }

    private static bool later;
    private void Update()
    {
        later = false;
    }
    private float fpsSecondTimer = 0f;
    private int fpsSecondFrames = 0;
    private float fpsSecondTimer2 = 0f;
    private int fpsSecondFrames2 = 0;
    
    private int frame = 0;
    private Texture2D rescaleTex;
    private int maxBounces;
    [SerializeField] int bounces;
    
    private void LateUpdate()
    {
        if (hasBeenSetup == false)
        {
            Setup();
            hasBeenSetup = true;
        }

        if (_deviceController.RecordVideo == false)
        {
            fpsSecondTimer += Time.deltaTime;
            fpsSecondFrames++;
            fpsSecondTimer2 += Time.deltaTime;
            fpsSecondFrames2++;
            if (fpsSecondTimer2 >= 0.25f)
            {
                if (fpsSecondFrames2 > 14f)
                {
                    bounces = Mathf.Min(bounces+1, maxBounces);
                }
                else if (fpsSecondFrames2 < 11f)
                {
                    bounces = Mathf.Max(bounces-1, Mathf.Min(2,maxBounces));
                }
                fpsSecondTimer2 = 0;
                fpsSecondFrames2 = 0;
            }
            if (fpsSecondTimer >= 0.9999f)
            {
                if (_material.IsKeywordEnabled("MEGA_SAMPLES") && fpsSecondFrames < 42) {
                    _material.DisableKeyword("MEGA_SAMPLES");
                    Debug.Log("Less Samples.");
                    bounces = 2;
                    fpsSecondTimer = 0;
                    fpsSecondFrames = 0;
                }
            }
            else if (fpsSecondTimer >= 1.9999f)
            {
                if (fpsSecondFrames > 115 && _material.IsKeywordEnabled("MEGA_SAMPLES") == false)
                {
                    _material.EnableKeyword("MEGA_SAMPLES");
                    Debug.Log("More Samples.");
                } 
                fpsSecondTimer = 0;
                fpsSecondFrames = 0;
            }
        }
        else
        {
            _material.EnableKeyword("MEGA_SAMPLES");
            bounces = Mathf.Min(bounces+1, maxBounces);
        }


        if (_deviceController != null && !_deviceController.Device.player)
        {
            if (!_audioSource.isPlaying && Time.time < 0.5f)
            {
                _audioSource.Play();
                _audioSource.Pause();
            }
        }
        else if (_deviceController != null)
        {
            if(_deviceController.RecordVideo) {
                _audioSource.Pause();
                ScreenCapture.CaptureScreenshot("Record/Frame_" + frame + ".png");
                frame++;
                _audioSource.time = frame / 60.0f;
                later = true;
            } else if (!_audioSource.isPlaying && Time.time < 0.5f)
            {
                _audioSource.Play();
            }
        }

        if (!deviceProp && _deviceController != null)
        {
            _deviceController.Device.Pause += Paused;
            _deviceController.Device.SetRow += SetRow;
            deviceProp = true;
        }
        float row = (_audioSource.time + 1f/60f) * row_rate;
        ROWI = row;
        

        _material.SetInt(IFrame,Time.frameCount);
        _material.SetFloat(IDeltaTime,Time.deltaTime);
        if (prevFrameRow != row || (Time.frameCount%20) == 0)
        {
            if (_deviceController == null) return;
            _material.SetVector(CameraPosition, new Vector4(
                _deviceController.Device.GetTrack("CameraPositionX").GetValue(row),
                _deviceController.Device.GetTrack("CameraPositionY").GetValue(row),
                _deviceController.Device.GetTrack("CameraPositionZ").GetValue(row),
                0f
            ));
            _material.SetVector(CameraRotation, new Vector4(
                _deviceController.Device.GetTrack("CameraRotationX").GetValue(row),
                _deviceController.Device.GetTrack("CameraRotationY").GetValue(row),
                _deviceController.Device.GetTrack("CameraRotationZ").GetValue(row),
                0f
            ));
            _material.SetVector(PrevCameraPosition, new Vector4(
                _deviceController.Device.GetTrack("CameraPositionX").GetValue(prevFrameRow),
                _deviceController.Device.GetTrack("CameraPositionY").GetValue(prevFrameRow),
                _deviceController.Device.GetTrack("CameraPositionZ").GetValue(prevFrameRow),
                0f
            ));
            _material.SetVector(PrevCameraRotation, new Vector4(
                _deviceController.Device.GetTrack("CameraRotationX").GetValue(prevFrameRow),
                _deviceController.Device.GetTrack("CameraRotationY").GetValue(prevFrameRow),
                _deviceController.Device.GetTrack("CameraRotationZ").GetValue(prevFrameRow),
                0f
            ));
            _material.SetVector(LightDirection, new Vector4(
                _deviceController.Device.GetTrack("LightDirectionX").GetValue(row),
                _deviceController.Device.GetTrack("LightDirectionY").GetValue(row),
                _deviceController.Device.GetTrack("LightDirectionZ").GetValue(row),
                0f
            ));
            _material.SetVector(LightColor, new Vector4(
                _deviceController.Device.GetTrack("lightColorR").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("lightColorG").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("lightColorB").GetValue(row)+0.001f,
                0f
            ));
            _material.SetVector(ScatterLightColor, new Vector4(
                _deviceController.Device.GetTrack("scatterLightColorR").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("scatterLightColorG").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("scatterLightColorB").GetValue(row)+0.001f,
                0f
            ));
            _material.SetVector(BackgroundLight, new Vector4(
                _deviceController.Device.GetTrack("backgroundLightR").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("backgroundLightG").GetValue(row)+0.001f,
                _deviceController.Device.GetTrack("backgroundLightB").GetValue(row)+0.001f,
                0f
            ));
            _material.SetVector(BulbPosition, new Vector4(
                _deviceController.Device.GetTrack("bulbPositionX").GetValue(row),
                _deviceController.Device.GetTrack("bulbPositionY").GetValue(row),
                _deviceController.Device.GetTrack("bulbPositionZ").GetValue(row),
                0f
            ));
            _material.SetVector(BulbColor, new Vector4(
                _deviceController.Device.GetTrack("bulbColorR").GetValue(row),
                _deviceController.Device.GetTrack("bulbColorG").GetValue(row),
                _deviceController.Device.GetTrack("bulbColorB").GetValue(row),
                0f
            ));
            _material.SetFloat(BulbSize, _deviceController.Device.GetTrack("bulbSize").GetValue(row));
            _material.SetVector(RotationPhase, new Vector4(
                _deviceController.Device.GetTrack("RotationPhaseX").GetValue(row),
                _deviceController.Device.GetTrack("RotationPhaseY").GetValue(row),
                _deviceController.Device.GetTrack("RotationPhaseZ").GetValue(row),
                _deviceController.Device.GetTrack("RotationPhaseW").GetValue(row)
            ));
            _material.SetVector(JuliaOffset, new Vector4(
                _deviceController.Device.GetTrack("JuliaOffsetX").GetValue(row),
                _deviceController.Device.GetTrack("JuliaOffsetY").GetValue(row),
                _deviceController.Device.GetTrack("JuliaOffsetZ").GetValue(row),
                _deviceController.Device.GetTrack("JuliaOffsetW").GetValue(row)
            ));
            _material.SetVector(JuliaPosition, new Vector4(
                _deviceController.Device.GetTrack("JuliaPositionX").GetValue(row),
                _deviceController.Device.GetTrack("JuliaPositionY").GetValue(row),
                _deviceController.Device.GetTrack("JuliaPositionZ").GetValue(row),
                0.0f
            ));
            _material.SetVector(JuliaRotation, new Vector4(
                _deviceController.Device.GetTrack("JuliaRotationX").GetValue(row),
                _deviceController.Device.GetTrack("JuliaRotationY").GetValue(row),
                _deviceController.Device.GetTrack("JuliaRotationZ").GetValue(row),
                0.0f
            ));
            _material.SetVector(BunnyPosition, new Vector4(
                _deviceController.Device.GetTrack("BunnyPositionX").GetValue(row),
                _deviceController.Device.GetTrack("BunnyPositionY").GetValue(row),
                _deviceController.Device.GetTrack("BunnyPositionZ").GetValue(row),
                0f
            ));
            _material.SetFloat(FogDistance, _deviceController.Device.GetTrack("fogDistance").GetValue(row));
            _material.SetFloat(FogStrength, _deviceController.Device.GetTrack("fogStrength").GetValue(row));
            _material.SetFloat(BunAnimation, _deviceController.Device.GetTrack("bunAnimation").GetValue(row));
            _material.SetFloat(ITime, _audioSource.time);
            _material.SetFloat(GroundLevel, _deviceController.Device.GetTrack("groundLevel").GetValue(row));
            _material.SetFloat(MotionBlur, _deviceController.Device.GetTrack("motionBlur").GetValue(row));

            _material.SetFloat("polar", _deviceController.Device.GetTrack("polar").GetValue(row));

            _material.SetFloat("fieldOfView", _deviceController.Device.GetTrack("fieldOfView").GetValue(row));
            _material.SetFloat("prevFieldOfView",
                _deviceController.Device.GetTrack("fieldOfView").GetValue(prevFrameRow));



            _material.SetVector("mirror", new Vector4(
                _deviceController.Device.GetTrack("MirrorX").GetValue(row),
                _deviceController.Device.GetTrack("MirrorY").GetValue(row),
                _deviceController.Device.GetTrack("MirrorZ").GetValue(row),
                0f
            ));
            
            RenderHistory renderHistory = new RenderHistory();
            if (_deviceController.Device.GetTrack("FAST_MARCH").GetValue(prevFrameRow) > 0.5f)
            {
                _material.EnableKeyword("FAST_MARCH");
                renderHistory.FAST_MARCH = true;
            }
            else
            {
                _material.DisableKeyword("FAST_MARCH");
                renderHistory.FAST_MARCH = false;
            }
            if (_deviceController.Device.GetTrack("BUNNY_ON").GetValue(prevFrameRow) > 0.5f)
            {
                _material.EnableKeyword("BUNNY_ON");
                renderHistory.BUNNY_ON = true;
            }
            else
            {
                _material.DisableKeyword("BUNNY_ON");
                renderHistory.BUNNY_ON = false;
            }
            if (_deviceController.Device.GetTrack("JULIA_ON").GetValue(prevFrameRow) > 0.5f)
            {
                _material.EnableKeyword("JULIA_ON");
                renderHistory.JULIA_ON = true;
            }
            else
            {
                _material.DisableKeyword("JULIA_ON");
                renderHistory.JULIA_ON = false;
            }
            if (_deviceController.Device.GetTrack("SURFACE_ON").GetValue(prevFrameRow) > 0.5f)
            {
                _material.EnableKeyword("SURFACE_ON");
                renderHistory.SURFACE_ON = true;
            }
            else
            {
                _material.DisableKeyword("SURFACE_ON");
                renderHistory.SURFACE_ON = false;
            }
            if (_deviceController.Device.GetTrack("SURFACE_HIGH").GetValue(prevFrameRow) > 0.5f)
            {
                _material.EnableKeyword("SURFACE_HIGH");
                renderHistory.SURFACE_HIGH = true;
            }
            else
            {
                _material.DisableKeyword("SURFACE_HIGH");
                renderHistory.SURFACE_HIGH = false;
            }
            if (_deviceController.Device.GetTrack("skyboxPower").GetValue(prevFrameRow) > 0.01f)
            {
                _material.EnableKeyword("SKYBOX_ON");
                renderHistory.SKYBOX_ON = true;
            }
            else
            {
                _material.DisableKeyword("SKYBOX_ON");
                renderHistory.SKYBOX_ON = false;
            }
            if (_deviceController.Device.GetTrack("WORM_ON").GetValue(prevFrameRow) > 0.01f)
            {
                _material.EnableKeyword("WORM_ON");
                renderHistory.WORM_ON = true;
            }
            else
            {
                _material.DisableKeyword("WORM_ON");
                renderHistory.WORM_ON = false;
            }
            if (_deviceController.Device.GetTrack("LIGHTS").GetValue(prevFrameRow) > 0.01f)
            {
                _material.EnableKeyword("LIGHTS");
                renderHistory.LIGHTS = true;
            }
            else
            {
                _material.DisableKeyword("LIGHTS");
                renderHistory.LIGHTS = false;
            }

            if (!renderHistories.Contains(renderHistory))
            {
                renderHistories.Add(renderHistory);
            }
            
            _material.SetFloat("skyboxPower", _deviceController.Device.GetTrack("skyboxPower").GetValue(row));

            _material.SetFloat("sunSize", _deviceController.Device.GetTrack("sunSize").GetValue(row) / 20.0f);
            _material.SetFloat("sharpen", _deviceController.Device.GetTrack("sharpen").GetValue(row));
            _material.SetFloat("MAX_DISTANCE", _deviceController.Device.GetTrack("MAX_DISTANCE").GetValue(row));
            _material.SetFloat("modulo", _deviceController.Device.GetTrack("modulo").GetValue(row));
            maxBounces = (int)_deviceController.Device.GetTrack("MAX_SAMPLES").GetValue(row);
            _material.SetFloat("MAX_SAMPLES", bounces);
            _material.SetFloat("EPSILON", _deviceController.Device.GetTrack("EPSILON").GetValue(row));
            _material.SetVector("kleinianPosition", new Vector4(
                _deviceController.Device.GetTrack("kleinianPositionX").GetValue(row),
                _deviceController.Device.GetTrack("kleinianPositionY").GetValue(row),
                _deviceController.Device.GetTrack("kleinianPositionZ").GetValue(row),
                0.0f
            ));
            _material.SetFloat("limitSpace", _deviceController.Device.GetTrack("RAY_STEPS").GetValue(row));
            
            
            _material.SetVector("Gain", new Vector4( 
                _deviceController.Device.GetTrack("Gain_R").GetValue(row),
                _deviceController.Device.GetTrack("Gain_G").GetValue(row),
                _deviceController.Device.GetTrack("Gain_B").GetValue(row),
                0.0f));
            _material.SetVector("Gamma", new Vector4( 
                _deviceController.Device.GetTrack("Gamma_R").GetValue(row),
                _deviceController.Device.GetTrack("Gamma_G").GetValue(row),
                _deviceController.Device.GetTrack("Gamma_B").GetValue(row),
                0.0f));
            _material.SetVector("Lift", new Vector4( 
                _deviceController.Device.GetTrack("Lift_R").GetValue(row),
                _deviceController.Device.GetTrack("Lift_G").GetValue(row),
                _deviceController.Device.GetTrack("Lift_B").GetValue(row),
                0.0f));
            _material.SetVector("Presaturation", new Vector4( 
                _deviceController.Device.GetTrack("Presaturation").GetValue(row),
                _deviceController.Device.GetTrack("Presaturation").GetValue(row),
                _deviceController.Device.GetTrack("Presaturation").GetValue(row),
                0.0f));
            _material.SetVector("TemperatureStrenth", new Vector4( 
                _deviceController.Device.GetTrack("TemperatureStrenth").GetValue(row),
                _deviceController.Device.GetTrack("TemperatureStrenth").GetValue(row),
                _deviceController.Device.GetTrack("TemperatureStrenth").GetValue(row),
                0.0f));
            _material.SetFloat("Temperature", 
                _deviceController.Device.GetTrack("Temperature").GetValue(row));
            _material.SetFloat("Hue", 
                _deviceController.Device.GetTrack("Hue").GetValue(row));
            _material.SetFloat("stepMag", 
                _deviceController.Device.GetTrack("stepMag").GetValue(row));
        }

        if (!_deviceController.Device.player)
        {
            bool connected = _deviceController.Device.Update((int) row);
            if (!connected)
            {
                _deviceController.Device.Connect();
            }
        }

        prevFrameRow = row;
        
        if (Input.GetKey("escape") || (Time.time>240 && !_audioSource.isPlaying))
        {
            Application.Quit();
        }
    }

    void OnApplicationQuit()
    {
        foreach (var history in renderHistories)
        {
            Debug.Log(history);
        }
        _deviceController.Device.SaveTracks();
    }
    private void SetRow(int row)
    {
        _audioSource.time = row / row_rate;
    }

    private void Paused(bool pause)
    {
        if (Time.time - pauseCooldown < 0.1f)
        {
            return;
        }
        pauseCooldown = Time.time;
        if (pause)
        {
            _audioSource.Pause();
        }
        else
        {
            _audioSource.UnPause();
        }
    }
}