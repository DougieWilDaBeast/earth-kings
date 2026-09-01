shader_type canvas_item;
// Cinematic overlay: darkens the edges and lays a little drifting haze over the
// country so a flat map reads as weather rather than as a spreadsheet. Unlike
// the title backdrop this is transparent in the middle — there is something
// underneath it worth seeing.

uniform vec3 haze_tint : source_color = vec3(0.42, 0.44, 0.55);
uniform float haze_strength : hint_range(0.0, 1.0) = 0.16;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.014;
uniform float vignette_strength : hint_range(0.0, 3.0) = 1.9;

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
	for (int i = 0; i < 4; i++) {
		sum += amp * value_noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return sum;
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * drift_speed;
	float haze = fbm(vec2(uv.x * 3.2 + t, uv.y * 2.1 - t * 0.4)) * haze_strength;

	vec2 d = uv - vec2(0.5);
	float dark = clamp(vignette_strength * dot(d, d) * 1.35, 0.0, 1.0);

	// Haze over the whole frame, black closing in at the corners.
	vec3 col = mix(haze_tint, vec3(0.02, 0.02, 0.03), dark);
	COLOR = vec4(col, clamp(haze + dark, 0.0, 1.0));
}
