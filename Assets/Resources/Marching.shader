Shader "Path Marcher" {
   Properties {
      iResolution ("Resolution", Vector) = (0., 0., 0., 1.0)
      iChannel0 ("iChannel0", 2D) = "" {}
      iTime ("Time", Float) = 0.0
      iTimeDelta ("Time Delta", Float) = 0.015
      iFrame ("Frame", Int) = 0
   	  cameraPosition ("Camera Position", Vector) = (0.0,0.0,0.0,0.0)
   	  cameraRotation ("Camera Rotation", Vector) = (0.0,0.0,0.0,0.0) 
   	  prevCameraPosition ("Previous Camera Position", Vector) = (0.0,0.0,0.0,0.0)
   	  prevCameraRotation ("Previous Camera Rotation", Vector) = (0.0,0.0,0.0,0.0)
      lightDirection ("Light Direction", Vector) = (0.0,0.0,0.0,0.0)
      lightColor ("Light Color", Vector) = (0.0,0.0,0.0,0.0)
      rotationPhase ("Rotation Phase", Vector) = (0.0,0.0,0.0,0.0)
   	
   }
   
   SubShader {
      Pass {
      	
         Cull Off
        ZWrite Off
        ZTest Always
         GLSLPROGRAM
		 #pragma multi_compile __ FAST_MARCH
         #pragma multi_compile __ BUNNY_ON
         #pragma multi_compile __ JULIA_ON
         #pragma multi_compile __ SURFACE_ON
         #pragma multi_compile __ SURFACE_HIGH
         #pragma multi_compile __ SKYBOX_ON
         #pragma multi_compile __ WORM_ON
         #pragma multi_compile __ LIGHTS
         #pragma multi_compile __ MEGA_SAMPLES
         
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
uniform vec4 iResolution;uniform sampler2D iChannel0;uniform float iTime,iTimeDelta;uniform int iFrame;uniform vec4 cameraPosition,cameraRotation,prevCameraPosition,prevCameraRotation,lightDirection,lightColor,rotationPhase,juliaOffset,bunnyPosition,juliaPosition,scatterLightColor,backgroundLight,juliaRotation,bulbPosition,bulbColor,mirror;uniform float bulbSize,fogDistance,fogStrength,bunAnimation,groundLevel,motionBlur,polar,fieldOfView,prevFieldOfView,sunSize,MAX_DISTANCE,modulo,MAX_SAMPLES,EPSILON,skyboxPower;uniform vec3 kleinianPosition;uniform float limitSpace,stepMag;uniform sampler2D visyTex;uniform float visy_overlay;uniform sampler2D _MainTex;
#define RAY_STEPS 122
#ifdef MEGA_SAMPLES
#define maxPixelSamples 8
#else
#define maxPixelSamples 5
#endif
const float PI=3.14159,TWOPI=PI*2.;float firstHit=0.;struct Ray{vec3 position;vec3 direction;vec4 carriedLight;vec3 light;};struct Material{vec4 carriedLight;vec3 emit;float scatter;};const uint samples=1103515245U;vec3 hash(uvec3 v){v=(v>>8U^v.yzx)*samples;v=(v>>8U^v.yzx)*samples;v=(v>>8U^v.yzx)*samples;return vec3(v)*(1./float(-1U));}vec2 hash2(float v){return fract(sin(vec2(v,v+1.))*vec2(43758.5,22578.1));}mat3 rotationMatrix(vec3 v,float m){v=normalize(v);float z=sin(m),y=cos(m),i=1.-y;return mat3(i*v.x*v.x+y,i*v.x*v.y-v.z*z,i*v.z*v.x+v.y*z,i*v.x*v.y+v.z*z,i*v.y*v.y+y,i*v.y*v.z-v.x*z,i*v.z*v.x-v.y*z,i*v.y*v.z+v.x*z,i*v.z*v.z+y);}float sdSphere(vec3 v,float y){return length(v)-y;}float sdBox(in vec3 v,in vec3 y){vec3 n=abs(v)-y;return min(max(n.x,max(n.y,n.z)),0.)+length(max(n,0.));}vec2 hash(vec2 v){v=vec2(dot(v,vec2(127.1,311.7)),dot(v,vec2(269.5,183.3)));return-1.+2.*fract(sin(v)*43758.5);}float fOpUnionRound(float v,float y,float m){vec2 z=max(vec2(m-v,m-y),vec2(0));return max(m,min(v,y))-length(z);}float sdCapsule(vec3 v,vec3 z,vec3 m,float y){vec3 n=v-z,x=m-z;float s=clamp(dot(n,x)/dot(x,x),0.,1.);return length(n-x*s)-y;}float getRing(float v){return 1.-min(pow(v,12.),1.);}float sdHexPrism(vec3 v,vec2 n){vec3 m=abs(v.zxy);return max(m.z-n.y,max(m.x*.866+m.y*.5,m.y)-n.x);}float sdCylinder(vec3 v,vec2 y){vec2 n=abs(vec2(length(v.xz),v.y))-y;return min(max(n.x,n.y),0.)+length(max(n,0.));}void pR(inout vec2 v,float m){v=cos(m)*v+sin(m)*vec2(v.y,-v.x);}float length6(vec3 v){v=v*v*v;v=v*v;return pow(v.x+v.y+v.z,1./6.);}float fractal(vec3 v){float m=length(v);v=v.yxz;float z=1.25;const int y=10;float f=0.;vec2 n=vec2(.2+rotationPhase.z,.04+rotationPhase.w),t=vec2(.2+rotationPhase.x,122.8+rotationPhase.y);vec3 s=vec3(-3.+juliaOffset.x,-2.15+juliaOffset.y,-.7+juliaOffset.z);pR(v.xy,.5);for(int r=0;r<y;r++){v=abs(v);v=v*z+s;pR(v.xz,t.x*3.14+cos(m)*n.y);pR(v.yz,t.y*3.14+sin(m)*n.x);f=length6(v);}return f*pow(z,-float(y))-.25;}vec3 coToPol(vec3 v){float m=atan(v.x,v.y),z=length(v.xy);return vec3(m,z,v.z);}float hash12(vec2 v){vec3 n=fract(vec3(v.xyx)*.1031);n+=dot(n,n.yzx+19.19);return fract((n.x+n.y)*n.z);}float voronoii(in vec3 v){v=fract(v)-.5;return dot(v,v);}float voronoiTile(in vec3 v){vec4 n;n.x=voronoii(v-vec3(.81,.62,.53));v.xy=vec2(v.y-v.x,v.y+v.x)*.7071;n.y=voronoii(v-vec3(.39,.2,.11));v.yz=vec2(v.z-v.y,v.z+v.y)*.7071;n.z=voronoii(v-vec3(.62,.24,.06));v.xz=vec2(v.z-v.x,v.z+v.x)*.7071;n.w=voronoii(v-vec3(.2,.82,.64));n.xy=min(n.xz,n.yw);return min(n.x,n.y)*2.66;}float hex(vec2 v){v.x*=1.1547;v.y+=mod(floor(v.x),2.)*.5;v=abs(mod(v,1.)-.5);return abs(max(v.x*1.5+v.y,v.y*2.)-1.);}float voronoiTile2(in vec3 v){vec4 n;n.x=voronoii(v-vec3(.81,.62,.53));v.xy=vec2(v.y-v.x,v.y+v.x)+hex(v.xy*.2);n.y=voronoii(v-vec3(.39,.2,.11));v.yz=vec2(v.z-v.y,v.z+v.y)+hex(v.yz*.2);n.z=voronoii(v-vec3(.62,.24,.06));v.xz=vec2(v.z-v.x,v.z+v.x)+hex(v.xz*.2);n.w=voronoii(v-vec3(.2,.82,.64));n.xy=min(n.xz,n.yw);return min(n.x,n.y)*.5;}float Noise(in float v){float m=floor(v),z=fract(v);z=z*z*(3.-2.*z);return mix(hash2(m).x,hash2(m+1.).x,z);}
#define CSize vec3(.808,.8,1.137)
float WeirdSet(vec3 v){float m=1.;for(int f=0;f<5;f++){v=2.*clamp(v,-CSize,CSize)-v;float z=dot(v,v),n=max(1.15/z,1.);v*=n;m*=n;}float z=length(v.xy),n=z*v.z,i=max(z-4.,-n/length(v)-.07+sin(2.+v.x+v.y+23.5*v.z)*.02),f=1.;f=f*f*f*f*.5;float y=dot(sin(v*.013),cos(v.zxy*.191))*f;return(i+y)/abs(m);}vec3 SurfaceColour(vec3 v){float f=0.,z=dot(v,v);for(int n=0;n<5;n++){vec3 m=2.*clamp(v,-CSize,CSize)-v;f+=abs(v.z-m.z);v=m;z=dot(v,v);float r=max(1.15/z,1.);v*=r;}return(.5+.5*sin(f*vec3(.6,-.9,4.9)))*.75+.15;}float fractaling(vec3 v){vec3 z=v,n=v;n.xz=mod(n.xz+1.,2.)-1.;n.y=mod(n.y+1.,2.)-1.;float f=sdBox(n,vec3(1.)),y=1.5+cos(v.z/3.)*.5;for(int r=0;r<3;r++){vec3 m=mod(v*y,2.)-1.9;y*=3.;vec3 i=abs(1.-3.*abs(m));float s=(min(max(i.x,i.y),min(max(i.y,i.z),max(i.z,i.x)))-1.)/y;f=max(s,f);}return f;}float getDistance(in vec3 v,out Material n){float m=sdSphere(v-bulbPosition.xyz,bulbSize);v.z=mix(v.z,mod(v.z,12.)-6.,modulo);v=mix(v,coToPol(v),polar);v.x=mix(v.x,abs(v.x),mirror.x);v.y=mix(v.y,abs(v.y),mirror.y);v.z=mix(v.z,abs(v.z),mirror.z);vec3 f=v-vec3(-12.,0.,0.)-juliaPosition.xyz;float z=1e+08;
#ifdef JULIA_ON
f*=rotationMatrix(vec3(1.,0.,0.),juliaRotation.x);f*=rotationMatrix(vec3(0.,1.,0.),juliaRotation.y);f*=rotationMatrix(vec3(0.,0.,1.),juliaRotation.z);z=fractal(f);
#endif
z=min(sdBox(v+vec3(groundLevel),vec3(1e+08,2.+voronoiTile2(v/32.)*12.,1e+08)),z);z=min(sdBox(v+bunnyPosition.xyz,vec3(1e+08,1e+08,1.)),z);vec3 i=v-bunnyPosition.xyz;i*=rotationMatrix(vec3(0.,1.,0.),1.5708);i.x=-abs(i.x);i*=.5;
#if WORM_ON
float y=WeirdSet((v-kleinianPosition).xzy);
#endif

#if LIGHTS
float s=max(fractaling((v-kleinianPosition)/12.),sdBox(v-kleinianPosition,vec3(16.,24.,16.)));
#endif
float r=z;r=min(m,r);
#if WORM_ON
r=min(r,y);
#endif

#if LIGHTS
r=min(r,s);
#endif
if(r==m){n.carriedLight=vec4(1.,1.,1.,1.);n.emit=bulbColor.xyz;n.scatter=1.1+length(bulbColor.xyz);
#if WORM_ON
}else if(r==y){float t=voronoiTile2(v*3.),x=pow(t*8.,1.4),a=voronoiTile(v*12.);n.carriedLight.xyz=SurfaceColour(v);n.carriedLight.w=1.;n.emit=vec3(0.);n.scatter=2.8;
#ifdef SURFACE_HIGH
r-=t/5.+.02;
#endif

#ifdef SURFACE_ON
r+=a/22.;
#endif   

#endif
 
#if LIGHTS
}else if(s==r){n.carriedLight=vec4(1.,1.,1.,1.);vec3 t=v-kleinianPosition;t/=vec3(2.,1.,4.);n.emit=vec3(1.,.34,.1)*(floor(mod(t.x,2.))*floor(mod(t.y,2.))*floor(mod(t.z,2.)));n.scatter=2.1;
#endif
}else{
#ifdef SURFACE_HIGH
r+=voronoiTile2(v);
#endif

#ifdef SURFACE_ON
r+=voronoiTile(v*7.)/5.;
#endif
n.carriedLight.xyz=vec3(1.);n.carriedLight.w=1.;n.emit=vec3(0.);n.scatter=1.8;}return r;}vec3 getLightDirection(){return lightDirection.xyz;}vec3 getLightColor(){return lightColor.xyz;}vec3 cameraRotationOperation(vec3 v,float m){if(m>0.){v*=rotationMatrix(vec3(1.,0.,0.),cameraRotation.x);v*=rotationMatrix(vec3(0.,1.,0.),cameraRotation.y);v*=rotationMatrix(vec3(0.,0.,1.),cameraRotation.z);}else{v*=rotationMatrix(vec3(0.,0.,1.),-cameraRotation.z);v*=rotationMatrix(vec3(0.,1.,0.),-cameraRotation.y);v*=rotationMatrix(vec3(1.,0.,0.),-cameraRotation.x);}return v;}vec3 prevCameraRotationOperation(vec3 v,float m){if(m>0.){v*=rotationMatrix(vec3(1.,0.,0.),prevCameraRotation.x);v*=rotationMatrix(vec3(0.,1.,0.),prevCameraRotation.y);v*=rotationMatrix(vec3(0.,0.,1.),prevCameraRotation.z);}else{v*=rotationMatrix(vec3(0.,0.,1.),-prevCameraRotation.z);v*=rotationMatrix(vec3(0.,1.,0.),-prevCameraRotation.y);v*=rotationMatrix(vec3(1.,0.,0.),-prevCameraRotation.x);}return v;}float shade(inout Ray v,vec3 z,float n,Material m){v.carriedLight*=m.carriedLight;v.light+=m.emit*v.carriedLight.xyz;return m.scatter;}void sampleSkybox(inout vec3 v,float m,float z,float y){vec3 n=normalize(cross(v,vec3(.01,1.,1.)));vec2 i=hash2(z);float f=sqrt(i.y),t=f*sin(6.2831*i.x),r=f*cos(6.2831*i.x),x=sqrt(sqrt(m)*(1.-i.y));v=normalize(mix(v,vec3(r*n+t*normalize(cross(n,v))+x*v),y));}vec3 shadeBackground(vec3 v){vec3 m=getLightDirection();m=normalize(m);vec3 z=getLightColor();float f=dot(v,vec3(0.,1.,0.)),n=dot(v,m);vec3 y=z*pow(max(n*(.1+sunSize),0.),4.);y+=.01*backgroundLight.xyz*pow(max(.7-n,0.),2.);y+=.1*scatterLightColor.xyz*pow(max(.2+n,0.),2.);return max(vec3(0.),y);}vec3 normal(Ray v,float y){Material m;float z=getDistance(vec3(EPSILON,0.,0.)+v.position,m)-y,n=getDistance(vec3(0.,EPSILON,0.)+v.position,m)-y,x=getDistance(vec3(0.,0.,EPSILON)+v.position,m)-y;return normalize(vec3(z,n,x));}Ray initialize(vec2 v,vec2 n,vec3 m){Ray f;f.light=vec3(0.);f.carriedLight=vec4(1.);f.direction=normalize(vec3(v+n,1.));f.direction.z/=tan(radians(fieldOfView));f.position=cameraPosition.xyz+f.direction*(-.5+m.z)*.001;f.direction=cameraRotationOperation(f.direction,1.);return f;}vec4 smpl(vec2 v,vec2 n,out vec3 z,int m,Ray f,out float y){int r=0;float s=0.,x=0.;vec4 i=vec4(0.);float t=1e+09,p=0.,c=0.,e=0.,u=1.;vec3 l=vec3(0.),w=f.position,b=f.direction;for(int S=0;S<RAY_STEPS;S++){Material a;float g=getDistance(f.position,a);t=min(t,g);
#if FAST_MARCH
f.position+=g*f.direction*.5*(1.+stepMag*p/100.);
#else
f.position+=g*f.direction*.5*(1.+stepMag*p*p/100.);
#endif
p+=g;if(g<EPSILON){{if(firstHit==0.){z=f.position;y=a.carriedLight.w;}vec3 h=normal(f,g);firstHit++;float d=shade(f,h,g,a);e+=d;sampleSkybox(f.direction,u,u+12.1231*dot(h,f.direction)+iTime+float(m),d*.5);f.position+=EPSILON*h;f.direction=reflect(f.direction,h);f.position+=EPSILON*f.direction;c++;r=1;if(c>MAX_SAMPLES){break;}}}else if(distance(w,f.position)>MAX_DISTANCE/min(1.+float(m),3.)||length(v)>limitSpace){vec3 d=shadeBackground(f.direction)*(12.*min(1.+c*2.,4.));if(t>EPSILON*1.5){f.light=d;break;}l+=f.light+f.carriedLight.xyz*d;u++;x=max(e,x);e=0.;break;}}l+=f.light;i+=vec4(l/u,1.);i.xyz=mix(i.xyz,shadeBackground(b)*12.,max(min((distance(w,z)-100.+fogDistance)/fogStrength,1.),0.));return i;}vec4 trace(vec2 v,vec2 n,out vec3 m){vec4 f=vec4(0.);float z=0.;vec2 y=gl_FragCoord.xy/iResolution.xy;float s=texture(iChannel0,y).w;for(int r=0;r<maxPixelSamples;r++){uvec3 i=uvec3(gl_FragCoord.xy,iFrame*maxPixelSamples+r);vec3 t=hash(i);vec2 x=t.xy-.5;x/=iResolution.xy;Ray e=initialize(v,x,t);e.direction*=1.+t.z/8.;f+=smpl(v,n,m,r,e,z);}return vec4(f.xyz/f.w,z);}vec4 reproject(vec3 v){vec3 n=normalize(v-prevCameraPosition.xyz)/1.5;n=prevCameraRotationOperation(n,-1.);n.z*=tan(radians(prevFieldOfView));n/=n.z;vec2 m=vec2(iResolution.x/iResolution.y,1.),f=n.xy;f/=m;f+=vec2(1.);f/=2.;if(f.x>0.&&f.x<1.&&f.y>0.&&f.y<1.){vec4 r=texture(iChannel0,f);r.w=mod(r.w,1.);return r;}return vec4(0.);}void mainImage(out vec4 v,in vec2 m){vec2 z=vec2(iResolution.x/iResolution.y,1.),n=m.xy/iResolution.xy,f=n;n=(2.*n-1.)*z;vec2 y=(2.*((m.xy+vec2(1.,1.))/iResolution.xy)-1.)*z-n;vec3 i=vec3(0.);vec4 t=trace(n,y,i);v=vec4(t.xyz,1./127.);v.xyz=pow(v.xyz,vec3(1./2.1));if(length(i)>0.){vec4 r=reproject(i)*(1.-motionBlur)*t.w;v+=vec4(r.xyz*(1.+motionBlur),1./127.)*(r.w*127.);v.xyz/=v.w*127.;}else{
#if SKYBOX_ON
v.xyz+=texture2D(_MainTex,n/vec2(4.5,2.)-vec2(.5)).xyz*skyboxPower;
#endif
v.w=0.;}v.xyz=min(max(v.xyz,vec3(0.)),vec3(1.));}void main(){vec4 v;vec2 m=gl_FragCoord.xy;mainImage(v,m);gl_FragColor=v;}
          
         #endif

         ENDGLSL
      }
   }
}