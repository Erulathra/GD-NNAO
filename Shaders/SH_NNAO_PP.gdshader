shader_type spatial;
render_mode depth_draw_never, unshaded;

#define FW 31
#define HW ((FW-1)/2)

#define NSAMPLES 32

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_roughness_texture : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform sampler2D F0;
uniform sampler2D F1;
uniform sampler2D F2;
uniform sampler2D F3;

uniform vec4 F0a = vec4( 2.364370,  2.399485,  0.889055,  4.055205);
uniform vec4 F0b = vec4(-1.296360, -0.926747, -0.441784, -3.308158);
uniform vec4 F1a = vec4( 1.418117,  1.505182,  1.105307,  1.728971);
uniform vec4 F1b = vec4(-0.491502, -0.789398, -0.328302, -1.141073);
uniform vec4 F2a = vec4( 1.181042,  1.292263,  2.136337,  1.616358);
uniform vec4 F2b = vec4(-0.535625, -0.900996, -0.405372, -1.030838);
uniform vec4 F3a = vec4( 1.317336,  2.012828,  1.945621,  5.841383);
uniform vec4 F3b = vec4(-0.530946, -1.091267, -1.413035, -3.908190);

uniform vec4  Xmean = vec4( 0.000052, -0.000003, -0.000076,  0.004600);
uniform vec4  Xstd  = vec4( 0.047157,  0.052956,  0.030938,  0.056321);
uniform float Ymean =  0.000000;
uniform float Ystd  =  0.116180;

uniform mat4 W1 = mat4(
	vec4(-0.147624, -0.150471,  0.154306, -0.006904),
	vec4(0.303306,  0.057305, -0.240071,  0.036727),
	vec4(0.009158, -0.371759, -0.259837,  0.302215),
	vec4(-0.111847, -0.183312,  0.044680, -0.190296));

uniform mat4 W2 = mat4(
	vec4(0.212815,  0.028991,  0.105671, -0.111834),
	vec4(0.316173, -0.166099,  0.058121, -0.170316),
	vec4(0.135707, -0.478362, -0.156021, -0.413203),
	vec4(-0.097283,  0.189983,  0.019879, -0.260882));

uniform vec4 W3 = vec4( 0.774455,  0.778138, -0.318566, -0.523377);

uniform vec4  b0 = vec4( 0.428451,  2.619065,  3.756697,  1.636395);
uniform vec4  b1 = vec4( 0.566310,  1.877808,  1.316716,  1.091115);
uniform vec4  b2 = vec4( 0.033848,  0.036487, -1.316707, -1.067260);
uniform float b3 =  0.151472;

uniform vec4  alpha0 = vec4( 0.326746, -0.380245,  0.179183,  0.104307);
uniform vec4  alpha1 = vec4( 0.255981,  0.009228,  0.211068,  0.110055);
uniform vec4  alpha2 = vec4(-0.252365,  0.016463, -0.232611,  0.069798);
uniform float alpha3 = -0.553760;

uniform vec4  beta0 = vec4( 0.482399,  0.562806,  0.947146,  0.460560);
uniform vec4  beta1 = vec4( 0.670060,  1.090481,  0.461880,  0.322837);
uniform vec4  beta2 = vec4( 0.760696,  1.016398,  1.686991,  1.744554);
uniform float beta3 =  0.777760;

uniform float radius = 1.0;

uniform float cam_clip_near = 0.05;
uniform float cam_clip_far = 4000.0;

vec3 camera_space(vec2 uv, float depth, mat4 cam_inv_proj) {
	depth = max(depth, 1e-10);
	vec3 ndc = vec3(uv * 2.f - vec2(1.f), 2.f * depth - 1.f);
	vec4 position = cam_inv_proj * vec4(ndc, 1.f);
	
	return position.xyz / position.w;
}

vec3 rand(vec3 seed){
	return 2.0 * fract(sin(dot(seed, vec3(12.9898, 78.233, 21.317))) * vec3(43758.5453, 21383.21227, 20431.20563))-1.0;
}

vec4 prelu(vec4 x, vec4 alpha, vec4 beta) {
	return beta * max(x, 0.0) + alpha * min(x, 0.0);
}

float prelu_float(float x, float alpha, float beta) {
	return beta * max(x, 0.f) + alpha * min(x, 0.f);
}

vec2 spiral(float t, float l, float o) {
	return t * vec2(cos(l * 2.f * PI * (t + o)), sin(l * 2.f * PI * (t + o)));
}

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec3 normal = texture(normal_roughness_texture, SCREEN_UV).rgb;
    vec3 base = camera_space(SCREEN_UV, depth, INV_PROJECTION_MATRIX);
    vec3 seed = rand(base);

    /* First Layer */

    vec4 H0 = vec4(0);

    /* New Faster Sampler Method */
	for (int i = 0; i < NSAMPLES; i++) {    
		float scale = (PI/4.f) * float(FW*FW) * ((float(i+1)/float(NSAMPLES+1))/float(NSAMPLES/2));
		vec2 indx = spiral(float(i+1)/float(NSAMPLES+1), 2.5, 2.f*PI*seed.x);
  
    	vec4 next = PROJECTION_MATRIX * vec4(base + radius * (vec3(indx, 0)), 1);
    	vec3 norm = texture(normal_roughness_texture, ((next.xy / next.w)+ vec2(1.f)) / 2.f ).rgb;
		float depth =  texture(depth_texture, ((next.xy / next.w)+ vec2(1.f)) / 2.f ).r;
    	vec3 actu = camera_space(((next.xy / next.w)+vec2(1.f))/2.f, depth, INV_PROJECTION_MATRIX);
    	vec2 fltr = (indx * (float(HW + HW) + 0.5f)) / float(HW*2+2);
    
    	vec4 X = (1.f - clamp(length(actu - base) / radius, 0.f, 1.f)) * vec4(norm.xyz - normal, (actu.z - base.z) / radius);    

    	H0 += scale * transpose(mat4(
      		texture(F0, fltr) * F0a + F0b, texture(F1, fltr) * F1a + F1b,
      		texture(F2, fltr) * F2a + F2b, texture(F3, fltr) * F3a + F3b)) * ((X - Xmean) / Xstd);
  }
  
	H0 = prelu(H0 + b0, alpha0, beta0);

	/* Other Layers */

	vec4  H1 = prelu(W1 * H0 + b1, alpha1, beta1);
	vec4  H2 = prelu(W2 * H1 + b2, alpha2, beta2);
	float Y  = prelu_float(dot(W3, H2) + b3, alpha3, beta3);

	/* Output */

	ALBEDO = 1.0-vec3(clamp(Y * Ystd + Ymean, 0.0, 1.0));
}
