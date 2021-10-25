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
         uniform vec4 iResolution;
         uniform sampler2D iChannel0;
         uniform float iTime;
         uniform float iTimeDelta;
         uniform int iFrame;
         uniform vec4 cameraPosition;
         uniform vec4 cameraRotation;
         uniform vec4 prevCameraPosition;
         uniform vec4 prevCameraRotation;
         uniform vec4 lightDirection;
         uniform vec4 lightColor;
         uniform vec4 rotationPhase;
         uniform vec4 juliaOffset;
         uniform vec4 bunnyPosition;
         uniform vec4 juliaPosition;
         uniform vec4 scatterLightColor;
         uniform vec4 backgroundLight;
         uniform vec4 juliaRotation;
         uniform vec4 bulbPosition;
         uniform vec4 bulbColor;
         uniform vec4 mirror;
         uniform float bulbSize;
         uniform float fogDistance;
         uniform float fogStrength;
         uniform float bunAnimation;
         uniform float groundLevel;
         uniform float motionBlur;
         uniform float polar;
         uniform float fieldOfView;
         uniform float prevFieldOfView;
         uniform float sunSize;
         uniform float MAX_DISTANCE;
         uniform float modulo;
         uniform float MAX_SAMPLES;
         uniform float EPSILON;
         uniform float skyboxPower;
         uniform vec3 kleinianPosition;
         uniform float limitSpace;
         uniform float stepMag;
         uniform sampler2D visyTex;
         uniform float visy_overlay;

         uniform sampler2D  _MainTex;

#define RAY_STEPS 122
         #ifdef MEGA_SAMPLES
			#define maxPixelSamples 8
         #else
			#define maxPixelSamples 5
         #endif
const float PI = 3.14159269;
const float TWOPI = PI * 2.0;
float firstHit = 0.;
struct Ray {
    vec3 position;
    vec3 direction;
    
    vec4 carriedLight; // how much light the ray allows to pass at this point
    
    vec3 light; // how much light has passed through the ray
};
struct Material {
    vec4 carriedLight; // surface color and transparency
    vec3 emit; // emited light
    float scatter;
};

// iq's integer hash https://www.shadertoy.com/view/XlXcW4
const uint samples = 1103515245U;
vec3 hash( uvec3 x ) {
    x = ((x>>8U)^x.yzx)*samples;
    x = ((x>>8U)^x.yzx)*samples;
    x = ((x>>8U)^x.yzx)*samples;
    return vec3(x)*(1.0/float(0xffffffffU));
}
vec2 hash2( float n ) {
    return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123));
}
// iq's rotation iirc
mat3 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,
                oc * axis.x * axis.y - axis.z * s,
                oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  
                oc * axis.y * axis.y + c,
                oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,
                oc * axis.y * axis.z + axis.x * s,
                oc * axis.z * axis.z + c);
}
float sdSphere( vec3 position, float size ) {
  return length(position) - size;
}
float sdBox( in vec3 p, in vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}
vec2 hash( vec2 p )
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)) );
	    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}
float fOpUnionRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}
float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float getRing(float l) {
    return 1.0-min(pow(l,12.),1.);
}
float sdHexPrism( vec3 p, vec2 h) { 
    vec3 q = abs(p.zxy);
    return max(q.z-h.y, max((q.x*0.866+q.y*0.5), q.y) - h.x);
}
float sdCylinder(vec3 p, vec2 h){
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float length6( vec3 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y + p.z, 1.0/6.0 );
}

float fractal(vec3 p)
{
   	float len = length(p);
    p=p.yxz;

    float scale = 1.25;
    const int iterations = 10;
	float l = 0.;
    
    vec2 animAmp = vec2(0.2 + rotationPhase.z,0.04 + rotationPhase.w);
	vec2 phaseLoc = vec2(0.2 + rotationPhase.x,122.8 + rotationPhase.y);
	
    
    vec3 juliaOffset = vec3(-3.+juliaOffset.x,-2.15+juliaOffset.y,-.7+juliaOffset.z);
     
    pR(p.xy,.5);
    
    for (int i=0; i<iterations; i++) {
		p = abs(p);
		p = p * scale + juliaOffset;
        
        pR(p.xz,phaseLoc.x*3.14 + cos(len)*animAmp.y);
		pR(p.yz,phaseLoc.y*3.14 + sin(len)*animAmp.x);		
        l=length6(p);
	}
	return l*pow(scale, -float(iterations))-.25;
}
vec3 coToPol(vec3 p) {
    float a = atan(p.x,p.y);
    float d=  length(p.xy);
    return vec3(a,d,p.z);
}
float hash12(vec2 p)
{
  vec3 p3  = fract(vec3(p.xyx) * .1031);
  p3 += dot(p3, p3.yzx + 19.19);
  return fract((p3.x + p3.y) * p3.z);
}
float celli(in vec3 p){ p = fract(p)-.5; return dot(p, p); }
float cellTile(in vec3 p){
    vec4 d; 
    d.x = celli(p - vec3(.81, .62, .53));
    p.xy = vec2(p.y-p.x, p.y + p.x)*.7071;
    d.y = celli(p - vec3(.39, .2, .11));
    p.yz = vec2(p.z-p.y, p.z + p.y)*.7071;
    d.z = celli(p - vec3(.62, .24, .06));
    p.xz = vec2(p.z-p.x, p.z + p.x)*.7071;
    d.w = celli(p - vec3(.2, .82, .64));
    d.xy = min(d.xz, d.yw);
    return min(d.x, d.y)*2.66; 
}
float hex(vec2 p) {
    p.x *= 0.57735*2.0;
	p.y += mod(floor(p.x), 2.0)*0.5;
	p = abs((mod(p, 1.0) - 0.5));
	return abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
}
float cellTile2(in vec3 p){
    vec4 d; 
    d.x = celli(p - vec3(.81, .62, .53));
    p.xy = vec2(p.y-p.x, p.y + p.x)+hex(p.xy*0.2);
    d.y = celli(p - vec3(.39, .2, .11));
    p.yz = vec2(p.z-p.y, p.z + p.y)+hex(p.yz*0.2);
    d.z = celli(p - vec3(.62, .24, .06));
    p.xz = vec2(p.z-p.x, p.z + p.x)+hex(p.xz*0.2);
    d.w = celli(p - vec3(.2, .82, .64));
    d.xy = min(d.xz, d.yw);
    return min(d.x, d.y)*0.5; 
}
         
float Noise( in float x )
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix(hash2(p).x, hash2(p+1.0).x, f);
}
 
#define CSize  vec3(.808, .8, 1.137)
float Map( vec3 p )
{
	float scale = 1.0;

	for( int i=0; i < 5;i++ )
	{
		p = 2.0 * clamp(p, -CSize, CSize) - p;
		float r2 = dot(p,p);
		float k = max((1.15)/r2, 1.);
		p     *= k;
		scale *= k;
	}
	float l = length(p.xy);
	float n = l * p.z; 
	float rxy = max(l - 4.0, -(n) / (length(p))-.07+sin(2.0+p.x+p.y+23.5*p.z)*.02);
    float x = 1.0;x =x*x*x*x*.5;
    float h = dot(sin(p*.013),(cos(p.zxy*.191)))*x;
	return ((rxy+h) / abs(scale));
    
}
vec3 Colour( vec3 p)
{
	float col	= 0.0;
	float r2	= dot(p,p);
	
	for( int i=0; i < 5;i++ )
	{
		vec3 p1= 2.0 * clamp(p, -CSize, CSize)-p;
		col += abs(p.z-p1.z);
		p = p1;
		r2 = dot(p,p);
		float k = max((1.15)/r2, 1.0);
		p *= k;
	}
	return (0.5+0.5*sin(col*vec3(.6 ,-.9 ,4.9)))*.75 + .15;
}

float fractaling( vec3 p) { 

    vec3 w = p;
    vec3 q = p;

    q.xz = mod( q.xz+1.0, 2.0 ) - 1.0; q.y = mod( q.y+1.0, 2.0 ) - 1.0;
    
    float d = sdBox(q,vec3(1.0));
    float s = 1.5+cos(p.z/3.)*0.5;
    for( int m=0; m<3; m++ )
    {
        vec3 a = mod( p * s, 2.0 )-1.9; s *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));
        float c = (min(max(r.x,r.y),min(max(r.y,r.z),max(r.z,r.x)))-1.0)/s;

        d = max( c, d );
   }
   return d;
}
float getDistance( in vec3 position, out Material material) {
	float bulbDistance = sdSphere(position-bulbPosition.xyz,bulbSize);
	position.z = mix(position.z,mod(position.z, 12.0) - 6.0, modulo);
	position = mix(position,coToPol(position),polar);
	position.x = mix(position.x,abs(position.x),mirror.x);
	position.y = mix(position.y,abs(position.y),mirror.y);
	position.z = mix(position.z,abs(position.z),mirror.z);
	vec3 position3 = position-vec3(-12.0,0.0,0.0)-juliaPosition.xyz;
    float rockDistance = 1e8;
	#ifdef JULIA_ON
		position3 *= rotationMatrix(vec3(1.0,0.0,0.0), juliaRotation.x);
		position3 *= rotationMatrix(vec3(0.0,1.0,0.0), juliaRotation.y);
		position3 *= rotationMatrix(vec3(0.0,0.0,1.0), juliaRotation.z);
		rockDistance = fractal(position3);
	#endif
	
    rockDistance = min(sdBox(position+vec3(groundLevel),vec3(1e8,2.0 + cellTile2(position/32.0)*12.0,1e8)),rockDistance);
	rockDistance = min( sdBox(position+bunnyPosition.xyz, vec3(1e8,1e8,1.0)), rockDistance);
    vec3 position2 = position - bunnyPosition.xyz;
    position2 *= rotationMatrix(vec3(0.0,1.0,0.0),3.141592/2.0);
    position2.x = -abs(position2.x);
    position2 *= 0.5;
	#if WORM_ON 
		float wormDist = Map( (position - kleinianPosition).xzy );
	#endif
	#if LIGHTS
		float lightDist = max(fractaling((position - kleinianPosition)/12.0), sdBox(position - kleinianPosition,vec3(16.0,24.0,16.0)));
	#endif
	float finalDistance = rockDistance;
    finalDistance = min(bulbDistance, finalDistance);
	#if WORM_ON
		finalDistance = min(finalDistance, wormDist);
	#endif
	#if LIGHTS
		finalDistance = min(finalDistance, lightDist);
	#endif
	    if(finalDistance == bulbDistance) {
		        material.carriedLight = vec4(1.0,1.0,1.0,1.0);
		        material.emit = bulbColor.xyz; // emited light
		        material.scatter = 2.1;
		#if WORM_ON
		    } else if(finalDistance == wormDist) {
		    	float a = cellTile2(position*3.0);
		    	float b = pow(a*8.0,1.4);
		    	float c = cellTile(position*12.0);
			    material.carriedLight.rgb = Colour( position); 
			    material.carriedLight.a = 1.0;
		    	material.emit = vec3(0.0); // emited light 
		    	material.scatter = 2.8;
	    	#ifdef SURFACE_HIGH
		        finalDistance -= a/5.0 + 0.02;
	    	#endif
	    	#ifdef SURFACE_ON
		        finalDistance += c/22.0;
	    	#endif
		    	#endif
		#if LIGHTS 
		    } else if(lightDist == finalDistance) {
		        material.carriedLight = vec4(1.0,1.0,1.0,1.0);
		    	vec3 p = position - kleinianPosition;
		    	p /= vec3(2.0,1.0,4.0);
		        material.emit = vec3(1.0,0.34,0.1) * ( floor(mod(p.x,2.0)) * floor(mod(p.y,2.0)) * floor(mod(p.z,2.0)) ); // emited light 
		        material.scatter = 2.1;
		#endif
	    }  else {
	    	#ifdef SURFACE_HIGH
		        finalDistance += cellTile2(position);
	    	#endif
	    	#ifdef SURFACE_ON
		        finalDistance += cellTile(position*7.0)/5.0;
	    	#endif
	        material.carriedLight.rgb = vec3(1.0);
	        material.carriedLight.a = 1.0;
	        material.emit = vec3(0.0); // emited light
	        material.scatter = 1.8;
	    }
		return finalDistance;
	}
	vec3 getLightDirection() {
	    return lightDirection.xyz;
	}
	vec3 getLightColor() {
	    return lightColor.xyz;
	}
	vec3 cameraRotationOperation(vec3 dir, float signer) {
	    if(signer > 0.) { 
	        dir *= rotationMatrix(vec3(1.0,0.0,0.0), cameraRotation.x );
	        dir *= rotationMatrix(vec3(0.0,1.0,0.0), cameraRotation.y );
	        dir *= rotationMatrix(vec3(0.0,0.0,1.0), cameraRotation.z );
	    } else {
	        dir *= rotationMatrix(vec3(0.0,0.0,1.0), -cameraRotation.z);
	        dir *= rotationMatrix(vec3(0.0,1.0,0.0), -cameraRotation.y);
	        dir *= rotationMatrix(vec3(1.0,0.0,0.0), -cameraRotation.x);
	    }
	    return dir;
	}
	vec3 prevCameraRotationOperation(vec3 dir, float signer) {
	    if(signer > 0.) { 
	        dir *= rotationMatrix(vec3(1.0,0.0,0.0), prevCameraRotation.x );
	        dir *= rotationMatrix(vec3(0.0,1.0,0.0), prevCameraRotation.y );
	        dir *= rotationMatrix(vec3(0.0,0.0,1.0), prevCameraRotation.z );
	    } else {
	        dir *= rotationMatrix(vec3(0.0,0.0,1.0), -prevCameraRotation.z);
	        dir *= rotationMatrix(vec3(0.0,1.0,0.0), -prevCameraRotation.y);
	        dir *= rotationMatrix(vec3(1.0,0.0,0.0), -prevCameraRotation.x);
	    }
	    return dir;
	}
	float shade(inout Ray ray, vec3 dir, float d, Material material)
	{
	    ray.carriedLight *= material.carriedLight;
	    ray.light += material.emit * ray.carriedLight.rgb;
	    return material.scatter;
	}
  //hemispherical sampling
	void sampleSkybox(inout vec3 dir, float samples, float count, float diffuse) {
	    vec3  uu  = normalize( cross( dir, vec3(0.01,1.0,1.0) ) );
	    vec2  aa = hash2( count );
	    float ra = sqrt(aa.y);
	    float ry = ra*sin(6.2831*aa.x);
	    float rx = ra*cos(6.2831*aa.x);
	    float rz = sqrt( sqrt(samples)*(1.0-aa.y) );
	    dir = normalize(mix(dir, vec3( rx*uu + ry*normalize( cross( uu, dir ) ) + rz*dir ), diffuse));
	}
	vec3 shadeBackground(vec3 dir) {
	    vec3 lightDirection = getLightDirection();
	    lightDirection = normalize( lightDirection);
	    vec3 lightColor = getLightColor();
	    
	    float bacsamplesgroundDiff = dot( dir, vec3( 0.0, 1.0, 0.0));
	    float lightPower = dot( dir, lightDirection);
	    vec3 bacsamplesgroundColor =  lightColor * pow( max( lightPower * (0.1 + sunSize), 0.0), 4.0);
		bacsamplesgroundColor += 0.01 * backgroundLight.xyz * pow( max( 0.7-lightPower, 0.0), 2.0); 
	    bacsamplesgroundColor += 0.1 * scatterLightColor.xyz * pow( max( 0.2+lightPower, 0.0), 2.0);
	    return max(vec3(0.0), bacsamplesgroundColor);
	}

	vec3 normal(Ray ray, float d) {
	    Material material;
	    float dx = getDistance(vec3(EPSILON, 0.0, 0.0) + ray.position, material) - d;
	    float dy = getDistance(vec3(0.0, EPSILON, 0.0) + ray.position, material) - d;
	    float dz = getDistance(vec3(0.0, 0.0, EPSILON) + ray.position, material) - d;
	    return normalize(vec3(dx, dy, dz));
	}
	Ray initialize(vec2 uv, vec2 suffle, vec3 rand) {
	    Ray r;
	    r.light = vec3(0.0);
	    r.carriedLight = vec4(1.0);
	    r.direction = normalize(vec3(uv+suffle, 1.0));
		r.direction.z /= tan(radians(fieldOfView));
	    r.position = cameraPosition.xyz + r.direction * (-0.5 + rand.z) * 0.001;
	    r.direction = cameraRotationOperation(r.direction, 1.0);
	    return r;
	} 
	vec4 smpl(vec2 uv, vec2 uvD, out vec3 position, int sampleCount, Ray ray, out float temporalSampling) {
	    int hit = 0;
	    float depth = 0.0;
	    float maxDiffuseSum = 0.0;
	    vec4 color = vec4( 0.0);
	    float minDistance = 10e8;
	    float totalDistance = 0.0;
	    float count = 0.0;
	    float diffuseSum = 0.0;
	    float samples = 1.0;
	    vec3 total = vec3(0.0);
	    vec3 startPosition = ray.position;
	    vec3 startDirection = ray.direction;
	    for( int i = 0; i < RAY_STEPS; i++) {
	        Material material;
	        float dist = getDistance( ray.position, material);
	        minDistance = min( minDistance, dist);
	    	#if FAST_MARCH
				ray.position += dist * ray.direction * 0.5 * (1.0 + stepMag * totalDistance / 100.0);
	    	#else
				ray.position += dist * ray.direction * 0.5 * (1.0 + stepMag * totalDistance * totalDistance / 100.0);
	    	#endif
	        totalDistance += dist;
	        if(dist < EPSILON) { 
	          { 
	                if(firstHit == 0.) {
	                    position = ray.position;
	                    temporalSampling = material.carriedLight.a;
	                }
	                //ray.position -= dist * ray.direction;
	                vec3 norm = normal( ray, dist);
	                //ray.position -= 2.0 * dist * ray.direction;
	                firstHit ++;
	                float diffuse = shade( ray, norm, dist, material);
	                diffuseSum += diffuse;

	                sampleSkybox(
	                    ray.direction, 
	                    samples, 
	                    samples + 12.12312 * dot( norm, ray.direction) + iTime + float(sampleCount), 
	                    diffuse * 0.5);

	                ray.position += 1.0 * EPSILON * norm;
	                ray.direction = reflect(ray.direction, norm);
	                ray.position += 1.0 * EPSILON * ray.direction;
	                
	                count ++;
	                hit = 1;
	          		if( count > MAX_SAMPLES) {
	                    break;
	                }
	            }
	        } else if (distance(startPosition,ray.position) > MAX_DISTANCE / min(1.0 + float(sampleCount),3.0) || length(uv) > limitSpace) {
	            vec3 bg = shadeBackground( ray.direction) * (12.0 * min(1.0 + count * 2.0, 4.0) );
	            if (minDistance > EPSILON*1.5) {
	                ray.light = bg;
	                break;
	            }
	            total += ray.light + ray.carriedLight.rgb * bg;
	            samples++;        
	            maxDiffuseSum = max( diffuseSum, maxDiffuseSum);
	            diffuseSum = 0.0;
	            break;
	        }
	    }
	    total += ray.light;
	    color += vec4( total / samples, 1.0);
        color.rgb = mix( color.rgb, shadeBackground( startDirection) * 12., max( min( (distance(startPosition,position) - 100.0 + fogDistance ) / fogStrength,1.0),0.0) );


        //float luminance = color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
        //color.rgb = vec3(luminance,luminance,luminance);
	    return color;
	}
	vec4 trace(vec2 uv, vec2 uvD, out vec3 position) {
	    vec4 color = vec4(0.0);
	    float temporalSampling = 0.0;
		vec2 uv2 = gl_FragCoord.xy / iResolution.xy;
	    float samples = texture(iChannel0, uv2).a;
	    for( int sampleCount = 0; sampleCount < maxPixelSamples ; sampleCount++) {
	        uvec3 seed = uvec3(gl_FragCoord.xy, iFrame*maxPixelSamples + sampleCount);
	        vec3 rand = hash(seed);
	        vec2 suffle = rand.xy - 0.5;
	        suffle /= iResolution.xy;
	        Ray ray = initialize(uv, suffle, rand);
	    	ray.direction *= 1.0 + rand.z / 8.0;
	        color += smpl( uv,  uvD, position, sampleCount, ray, temporalSampling);
	        /*if(samples == 0.0 && sampleCount > 0) {
	        	break;
	        }*/
	    }
	    return vec4( color.rgb / color.a, temporalSampling);
	}
	vec4 reproject( vec3 worldPos) { 
	    vec3 dir = normalize(worldPos - prevCameraPosition.xyz) / 1.5;
	    dir = prevCameraRotationOperation(dir, -1.0);
		dir.z *= tan(radians(prevFieldOfView));
	    dir /= dir.z ;
	    
	    vec2 aspect = vec2(iResolution.x/iResolution.y, 1.0);
	    vec2 uv = dir.xy;
	    uv /= aspect;
	    uv += vec2(1.0);
	    uv /= 2.0;
	    if(uv.x>0.0 && uv.x<1.0 && uv.y>0.0 && uv.y<1.0) {
	        vec4 tex = texture(iChannel0, uv);
	        tex.a = mod(tex.a, 1.0);
	        return tex;
	    }
	    return vec4(0.0);
	}

	void mainImage( out vec4 fragColor, in vec2 fragCoord )
	{
		//if(mod(fragCoord.x/8.0+fragCoord.x/8.0,2.0) == 0) discard;
		vec2 aspect = vec2(iResolution.x/iResolution.y, 1.0);
		vec2 uv = fragCoord.xy / iResolution.xy;
		vec2 p = uv;
		uv = (2.0 * uv - 1.0) * aspect;
		//if(abs(uv.y)>0.75) discard;

            vec2 uvD = ((2.0 * ((fragCoord.xy+vec2(1.0, 1.0)) / iResolution.xy) - 1.0) * aspect) - uv;
            vec3 position = vec3(0.0);
            vec4 light = trace(uv, uvD, position);
            fragColor = vec4( light.rgb, 1.0/127.0 );

            fragColor.rgb = pow( fragColor.rgb, vec3(1.0/2.1) );
			if(length(position)>0.){
                vec4 reprojectionColor = reproject( position) * (1.0 - motionBlur) * light.a;
                fragColor += vec4(reprojectionColor.rgb * (1.0 + motionBlur), 1.0/127.0) * (reprojectionColor.a * 127.0);
				fragColor.rgb /= fragColor.a * 127.0;
            } else {
				#if SKYBOX_ON
					fragColor.rgb += texture2D( _MainTex, (uv/vec2(4.5,2.0))-vec2(0.5)).rgb * skyboxPower;
				#endif
	            fragColor.a = 0.0;
            }
            fragColor.rgb = min(max(fragColor.rgb,vec3(0.0)),vec3(1.0));
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