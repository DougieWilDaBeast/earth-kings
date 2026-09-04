shader_type canvas_item;
// Cinematic vignette and drifting atmospheric haze over the world overview.

uniform vec4 haze_color : source_color = vec4(0.08, 0.09, 0.14, 0.28);
uniform vec4 vignette_color : source_color = vec4(0.02, 0.02, 0.03, 0.65);
uniform float vignette_radius : hint_range(0.1, 1.5) = 0.85;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV;
	float dist = distance(uv, vec2(0.5, 0.5));
	float vignette = smoothstep(vignette_radius - vignette_softness, vignette_radius + vignette_softness, dist);
	
	// Drifting ambient atmospheric shimmer
	float shimmer = sin(TIME * 0.8 + uv.y * 6.0) * 0.04 + cos(TIME * 0.6 + uv.x * 6.0) * 0.04;
	vec4 base_haze = haze_color + vec4(shimmer, shimmer, shimmer, 0.0);
	
	vec4 color = mix(base_haze, vignette_color, vignette);
	COLOR = color;
}
