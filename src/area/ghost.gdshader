// Somebody seen from afar, a ghost of themselves (play-test 7, call BR8): their own picture as light
// in one colour, brighter where they are bright, see-through as the node's modulate says.
shader_type canvas_item;

uniform vec4 wash : source_color = vec4(0.55, 0.77, 1.0, 1.0);

void fragment() {
	vec4 picture = texture(TEXTURE, UV);
	float light = dot(picture.rgb, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(min(wash.rgb * (1.0 + 0.7 * light), vec3(1.0)), picture.a * COLOR.a);
}
