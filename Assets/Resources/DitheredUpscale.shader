Shader "Dithered Upscale" {
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
         uniform sampler2D iChannel1;
         uniform vec4 iChannel0Resolution;
         uniform float iFrame;


void mainImage( out vec4 fragColor, in vec2 fragCoord ){
   if(mod(fragCoord.x + fragCoord.y + iFrame, 2.0) == 1.0)
   {
	   vec2 uv = fragCoord.xy / iResolution.xy;
      vec3 c = texture(iChannel0, uv).xyz;
      
	   fragColor = vec4(c, 1.0);
   } else
   {
	   vec2 uv = fragCoord.xy / iResolution.xy;
      vec3 c = texture(iChannel1, uv).xyz;
      
	   fragColor = vec4(c, 1.0);
   }
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