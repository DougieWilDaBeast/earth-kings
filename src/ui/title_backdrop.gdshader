shader_type canvas_item;
// Title backdrop: drifting mist over a night sky, warm glow from an off-screen fire.

uniform vec3 sky_top : source_color = vec3(0.027, 0.031, 0.051);
uniform vec3 sky_bottom : source_color = vec3(0.129, 0.098, 0.086);
uniform vec3 mist_tint : source_color = vec3(0.34, 0.33, 0.44);
uniform vec3 fire_tint : source_color = vec3(0.30, 0.15, 0.05);
uniform float mist_strength : hint_range(0.0, 1.0) = 0.34;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.018;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.15;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		sum += amp * value_noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return sum;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(sky_top, sky_bottom, smoothstep(0.0, 1.0, uv.y));

	float t = TIME * drift_speed;
	float near_sheet = fbm(vec2(uv.x * 3.0 + t, uv.y * 2.0 - t * 0.35));
	float far_sheet = fbm(vec2(uv.x * 6.5 - t * 1.7, uv.y * 3.5 + t * 0.2));
	float mist = near_sheet * 0.65 + far_sheet * 0.35;
	mist *= smoothstep(0.02, 0.9, uv.y);
	col += mist_tint * mist * mist_strength;

	float glow = 1.0 - clamp(length((uv - vec2(0.5, 1.06)) * vec2(1.0, 1.7)), 0.0, 1.0);
	col += fire_tint * pow(glow, 2.5);

	vec2 d = uv - vec2(0.5);
	col *= clamp(1.0 - vignette_strength * dot(d, d) * 1.9, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
