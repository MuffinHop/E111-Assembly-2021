Shader "Color Grading" {
   Properties {
      iResolution ("Resolution", Vector) = (0., 0., 0., 1.0)
      iChannel0 ("iChannel0", 2D) = "" {}
      iChannel0Resolution ("iChannel0Resolution", Vector) = (0., 0., 0., 1.0)
   }
   
   SubShader {
        Cull Off
        ZWrite Off
        ZTest Always
      Pass {
         GLSLPROGRAM

         // uniforms corresponding to properties

         #include "UnityCG.glslinc" 
            // defines _Object2World and _World2Object
         
         out vec4 position_in_world_space;

         #ifdef VERTEX
         
         void main()
         {
            mat4 modelMatrix = unity_ObjectToWorld;

            position_in_world_space = modelMatrix * gl_Vertex;
                        
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex; 
         }
         
         #endif 

         #ifdef FRAGMENT
         uniform vec2 iResolution;
         uniform sampler2D iChannel0;
         uniform vec4 iChannel0Resolution;
         uniform vec4 Gain;
         uniform vec4 Gamma;
         uniform vec4 Lift;
         uniform vec4 Presaturation;
         uniform vec4 TemperatureStrenth;
         uniform float Temperature;
         uniform float Hue;
         

// http://creativecommons.org/publicdomain/zero/1.0/

struct ColorGradingPreset {
  vec3 gain;
  vec3 gamma;
  vec3 lift;
  vec3 presaturation;
  vec3 colorTemperatureStrength;
  float colorTemperature; // in K
  float colorTemperatureBrightnessNormalization;  
};

vec3 colorTemperatureToRGB(const in float temperature){
  mat3 m = (temperature <= 6500.0) ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
                                          vec3(0.0, 1669.5803561666639, 2575.2827530017594),
                                          vec3(1.0, 1.3302673723350029, 1.8993753891711275)) :
                                     mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
                                          vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
                                          vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));
  return clamp(vec3(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2]), vec3(0.0), vec3(1.0));
}

vec3 colorGradingProcess(const in ColorGradingPreset p, in vec3 c){
  float originalBrightness = dot(c, vec3(0.2126, 0.7152, 0.0722));
  c = mix(c, c * colorTemperatureToRGB(p.colorTemperature), p.colorTemperatureStrength);
  float newBrightness = dot(c, vec3(0.2126, 0.7152, 0.0722));
  c *= mix(1.0, (newBrightness > 1e-6) ? (originalBrightness / newBrightness) : 1.0, p.colorTemperatureBrightnessNormalization);
  c = mix(vec3(dot(c, vec3(0.2126, 0.7152, 0.0722))), c, p.presaturation);
  return pow((p.gain * 2.0) * (c + (((p.lift * 2.0) - vec3(1.0)) * (vec3(1.0) - c))), vec3(0.5) / p.gamma);
}


ColorGradingPreset ColorGradingPreset1 = ColorGradingPreset(
  vec3(0.5),   // Gain
  vec3(0.5),   // Gamma
  vec3(0.5),   // Lift
  vec3(1.0),   // Presaturation
  vec3(0.0),   // Color temperature strength
  6500.0,      // Color temperature (in K)
  0.0          // Color temperature brightness normalization factor 
);
vec3 HueShift (in vec3 Color, in float Shift)
{
    vec3 P = vec3(0.55735)*dot(vec3(0.55735),Color);
    
    vec3 U = Color-P;
    
    vec3 V = cross(vec3(0.55735),U);    

    Color = U*cos(Shift*6.2832) + V*sin(Shift*6.2832) + P;
    
    return Color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
		vec2 aspect = vec2(iResolution.x/iResolution.y, 1.0);
	vec2 uv = fragCoord.xy / iResolution.xy;
		uv = (2.0 * uv - 1.0) * aspect;
    uv = fragCoord.xy / iResolution.xy;
    uv.y /= 0.66;
    uv.y -= 0.25;
    vec3 c = texture(iChannel0, uv).xyz;
    c.r = min(max(c.r,0.0),1.0);
    c.g = min(max(c.g,0.0),1.0);
    c.b = min(max(c.b,0.0),1.0);

    ColorGradingPreset ColorGrading = ColorGradingPreset(
      Gain.rgb,   // Gain
      Gamma.rgb,   // Gamma
      Lift.rgb,   // Lift
      Presaturation.rgb,   // Presaturation
      TemperatureStrenth.rgb,   // Color temperature strength
      Temperature,      // Color temperature (in K)
      0.0          // Color temperature brightness normalization factor 
    );
    
    c = colorGradingProcess(ColorGrading , c);
    c.r = min(max(c.r,0.0),1.0);
    c.g = min(max(c.g,0.0),1.0);
    c.b = min(max(c.b,0.0),1.0);
    c = HueShift (c, Hue);
    c.r = min(max(c.r,0.0),1.0);
    c.g = min(max(c.g,0.0),1.0);
    c.b = min(max(c.b,0.0),1.0);
    if(uv.y>1.0 || uv.y<0.0)
    {
        c=vec3(0.0);
    }
	fragColor = vec4(c, 1.0);
}
         void main()
         {
			   vec4 fragColor;
			   vec2 fragCoord = gl_FragCoord.xy;
			   mainImage( fragColor, fragCoord );
            gl_FragColor = fragColor;
         }
         
         #endif

         ENDGLSL
      }
   }
}