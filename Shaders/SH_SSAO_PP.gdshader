shader_type spatial;
render_mode depth_draw_never, unshaded;

#define NSAMPLES 32

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// uniform sampler2D depth_texture;

uniform float clip_near = 0.05f;
uniform float clip_far = 4000.f;

uniform float radius = 0.01f;
uniform float bias = 0.25f;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

vec3 camera_space(vec2 uv, float depth, mat4 cam_inv_proj) {
	depth = max(depth, 1e-10);
	vec3 ndc = vec3(uv * 2.f - vec2(1.f), 2.f * depth - 1.f);
	vec4 position = cam_inv_proj * vec4(ndc, 1.f);
	
	return position.xyz / position.w;
}

vec3 rand(vec3 seed){
	return 2.0 * fract(sin(dot(seed, vec3(12.9898, 78.233, 21.317))) * vec3(43758.5453, 21383.21227, 20431.20563))-1.0;
}

vec3 randomSpherePoint(vec3 rand) {
	float ang1 = (rand.x + 1.0) * PI; // [-1..1) -> [0..2*PI)
	float u = rand.y; // [-1..1), cos and acos(2v-1) cancel each other out, so we arrive at [-1..1)
	float u2 = u * u;
	float sqrt1MinusU2 = sqrt(1.0 - u2);
	float x = sqrt1MinusU2 * cos(ang1);
	float y = sqrt1MinusU2 * sin(ang1);
	float z = u;
	return vec3(x, y, z);
}

void fragment() {
	vec3 sample_sphere[32] = vec3[32](
	vec3(-0.68, -0.21, -0.00), vec3(-0.79,  0.40, -0.20), vec3(-0.10, -0.81, -0.35),
	vec3(-0.11, -0.24, -0.33), vec3(-0.39, -0.37, -0.65), vec3(-0.72,  0.22,  0.13),
	vec3(-0.42, -0.24, -0.57), vec3( 0.03,  0.09, -0.47), vec3(-0.30,  0.23,  0.36),
	vec3(-0.14, -0.48,  0.55), vec3(-0.33, -0.67,  0.40), vec3(-0.11,  0.06,  0.13),
	vec3( 0.26, -0.17, -0.43), vec3(-0.51, -0.34, -0.66), vec3( 0.13,  0.08,  0.26),
	vec3( 0.69, -0.35, -0.32), vec3( 0.52,  0.35,  0.58), vec3(-0.03, -0.75, -0.39),
	vec3( 0.07,  0.32,  0.21), vec3( 0.12,  0.25,  0.42), vec3( 0.80, -0.30, -0.09),
	vec3(-0.02,  0.68,  0.23), vec3(-0.72,  0.15, -0.63), vec3(-0.30,  0.69,  0.20),
	vec3( 0.44,  0.25,  0.52), vec3(-0.36, -0.09, -0.42), vec3( 0.69, -0.26, -0.04),
	vec3( 0.38, -0.46,  0.36), vec3(-0.25,  0.40, -0.32), vec3(-0.25,  0.85,  0.07),
	vec3(-0.27,  0.37, -0.59), vec3(-0.63, -0.52, -0.28));

	float depth = texture(depth_texture, SCREEN_UV).r;

	vec3 base = camera_space(SCREEN_UV, depth, INV_PROJECTION_MATRIX);
	vec3 seed = normalize(rand(base));

	float occ = 0.0;
	for(int i=0; i < NSAMPLES; i++)
	{
		vec3 next = base + radius * reflect(sample_sphere[i+16], seed);
		vec4 ntex = PROJECTION_MATRIX * vec4(next, 1);
		float ndepth = texture(depth_texture, (ntex.xy / ntex.w)*0.5+0.5).r;
		vec3 actu = camera_space((ntex.xy / ntex.w)*0.5+0.5, ndepth, INV_PROJECTION_MATRIX);
		float scale = float(length(base - actu) < radius);
		occ += float(actu.z < next.z);
	}

	ALBEDO = (vec3((2.0*occ) / float(NSAMPLES) + bias));
}
