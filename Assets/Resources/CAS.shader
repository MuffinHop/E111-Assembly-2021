Shader "CAS" {
   Properties {
      iResolution ("Resolution", Vector) = (0., 0., 0., 1.0)
      iChannel0 ("iChannel0", 2D) = "" {}
      iChannel0Resolution ("iChannel0Resolution", Vector) = (0., 0., 0., 1.0)
   }
   
   SubShader {
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
         uniform float sharpen;
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

  
    // Time varying pixel color
    vec3 col = texture(iChannel0, uv).xyz;

    // CAS algorithm
    float max_g = col.y;
    float min_g = col.y;
    vec4 uvoff = vec4(1,0,1,-1)/iChannel0Resolution.xxyy;
    vec3 colw;
    vec3 col1 = texture(iChannel0, uv+uvoff.yw).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw = col1;
    col1 = texture(iChannel0, uv+uvoff.xy).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    col1 = texture(iChannel0, uv+uvoff.yz).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    col1 = texture(iChannel0, uv-uvoff.xy).xyz;
    max_g = max(max_g, col1.y);
    min_g = min(min_g, col1.y);
    colw += col1;
    float d_min_g = min_g;
    float d_max_g = 1.-max_g;
    float A;
    if (d_max_g < d_min_g) {
        A = d_max_g / max_g;
    } else {
        A = d_min_g / max_g;
    }
    A = sqrt(A);
    A *= -sharpen;
    vec3 col_out = (col + colw * A) / (1.+4.*A); 
    
    fragColor.rgb = col;
    fragColor = vec4(col_out,1);
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