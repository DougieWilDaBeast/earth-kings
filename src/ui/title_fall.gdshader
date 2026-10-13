shader_type canvas_item;
// Title backdrop: the sky the sixteen fall through. Stars high up, two sheets of
// cloud lit from below, the curve of the world at the bottom with its far
// mountains, and the Tower standing over everything on the horizon.

uniform vec3 sky_top : source_color = vec3(0.020, 0.024, 0.060);
uniform vec3 sky_mid : source_color = vec3(0.075, 0.060, 0.115);
uniform vec3 sky_low : source_color = vec3(0.330, 0.150, 0.080);
uniform vec3 cloud_lit : source_color = vec3(0.560, 0.300, 0.170);
uniform vec3 cloud_dark : source_color = vec3(0.090, 0.075, 0.110);
uniform vec3 land : source_color = vec3(0.028, 0.024, 0.034);
uniform vec3 rim : source_color = vec3(0.900, 0.520, 0.250);
// Where the land meets the sky, as a share of the height from the top.
uniform float horizon : hint_range(0.5, 0.95) = 0.80;
// Where the Tower stands, as a share of the width.
uniform float tower_x : hint_range(0.0, 1.0) = 0.74;
uniform float drift_speed : hint_range(0.0, 0.2) = 0.012;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.05;

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
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	// x in the same units as y, so nothing stretches on a wide screen.
	vec2 p = vec2(uv.x * aspect, uv.y);
	float t = TIME * drift_speed;

	// The edge of the world bows down at the sides.
	float edge = horizon + 0.05 * pow(uv.x - 0.5, 2.0) * 4.0;

	// Sky: deep at the top, warm where the world's light comes up from below.
	float k = clamp(uv.y / edge, 0.0, 1.0);
	vec3 col = mix(sky_top, sky_mid, smoothstep(0.0, 0.55, k));
	col = mix(col, sky_low, smoothstep(0.55, 1.0, k) * 0.9);

	// Stars, thinning out as the sky warms.
	// Each star a soft point in its cell, sized in pixels so a tall screen
	// does not blow them up into squares.
	float star_scale = 140.0 / max(1.0, SCREEN_PIXEL_SIZE.y * 720.0);
	vec2 cell = floor(p * star_scale);
	vec2 in_cell = fract(p * star_scale) - 0.5;
	float star = step(0.9965, hash21(cell)) * smoothstep(0.22, 0.0, length(in_cell));
	float twinkle = 0.55 + 0.45 * sin(TIME * (1.0 + hash21(cell + 3.1) * 2.5) + hash21(cell) * 40.0);
	col += vec3(0.85, 0.82, 1.0) * star * twinkle * (1.0 - smoothstep(0.15, 0.6, k));

	// High cloud: thin and dark, drifting one way.
	float high = fbm(vec2(p.x * 2.2 + t * 1.6, p.y * 5.0 - t * 0.4));
	float high_mask = smoothstep(0.52, 0.78, high) * smoothstep(0.05, 0.35, k) * (1.0 - smoothstep(0.55, 0.8, k));
	col = mix(col, cloud_dark * 1.8, high_mask * 0.6);

	// Low cloud: a thick bank over the land, lit warm on its underside.
	float low = fbm(vec2(p.x * 1.6 - t * 2.4, p.y * 3.2 + t * 0.3));
	float low_mask = smoothstep(0.40, 0.70, low) * smoothstep(0.42, 0.80, k);
	float underlit = smoothstep(0.6, 1.0, k);
	col = mix(col, mix(cloud_dark, cloud_lit, underlit * 0.85), low_mask * 0.85);

	// Far mountains, a ragged line just above the edge of the world.
	float ridge = edge - 0.018 - 0.045 * fbm(vec2(p.x * 3.5, 1.7)) + 0.02;
	float mountains = step(ridge, uv.y);
	col = mix(col, mix(land * 2.4, sky_low * 0.35, 0.35), mountains * 0.85);

	// The Tower: a vast spire from the horizon high into the sky, tiered with
	// ledges, hazed by distance so it reads as far away and enormous.
	float tx = p.x - tower_x * aspect;
	float top = 0.28;
	float rise = clamp((edge - uv.y) / (edge - top), 0.0, 1.0);
	float half_width = mix(0.024, 0.006, pow(rise, 0.6));
	for (int i = 0; i < 5; i++) {
		float at = 0.16 + float(i) * 0.17;
		half_width += 0.005 * (1.0 - smoothstep(0.0, 0.012, abs(rise - at)));
	}
	half_width += 0.007 * smoothstep(0.955, 0.975, rise) * (1.0 - smoothstep(0.99, 1.0, rise));
	float in_tower = step(abs(tx), half_width) * step(top, uv.y) * step(uv.y, edge);
	vec3 stone = mix(land * 1.6, col, 0.28);
	// The light from below catches one side.
	stone += rim * 0.10 * smoothstep(0.3, 1.0, tx / half_width) * (1.0 - rise * 0.6);
	col = mix(col, stone, in_tower);
	// A light at its top, slowly pulsing.
	vec2 to_top = vec2(tx, uv.y - top);
	float beacon = exp(-pow(length(to_top) * 85.0, 2.0));
	col += vec3(1.0, 0.78, 0.45) * beacon * (0.6 + 0.4 * sin(TIME * 1.3));
	col += vec3(1.0, 0.6, 0.3) * exp(-length(to_top) * 20.0) * 0.14;

	// The land itself, with a bright rim of atmosphere along its edge.
	float below = step(edge, uv.y);
	float depth = clamp((uv.y - edge) / (1.0 - edge), 0.0, 1.0);
	vec3 ground = land * (1.0 + 0.6 * fbm(vec2(p.x * 9.0, uv.y * 14.0)));
	ground += rim * 0.10 * (1.0 - depth);
	col = mix(col, ground, below);
	col += rim * exp(-abs(uv.y - edge) * 140.0) * 0.55;
	col += rim * exp(-abs(uv.y - edge) * 18.0) * 0.08;

	vec2 d = uv - vec2(0.5);
	col *= clamp(1.0 - vignette_strength * dot(d, d) * 1.8, 0.0, 1.0);

	COLOR = vec4(col, 1.0);
}
