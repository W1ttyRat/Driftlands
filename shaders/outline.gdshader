shader_type canvas_item;
// Hover highlight: paints the sprite's edge pixels white.
// TEXTURE is sampled directly in fragment() (not passed into a helper function): passing it
// as a sampler2D argument makes Godot's shader compiler log a "custom_samplers" error.

float inside(vec2 uv) {
	return step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
}

void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE;
	vec2 sides[4] = vec2[](vec2(p.x, 0.0), vec2(-p.x, 0.0), vec2(0.0, p.y), vec2(0.0, -p.y));
	float around = 1.0;
	for (int i = 0; i < 4; i++) {
		vec2 uv = UV + sides[i];
		around *= texture(TEXTURE, uv).a * inside(uv);
	}
	if (COLOR.a > 0.0 && around < 1.0) {
		COLOR.rgb = vec3(1.0);
	}
}
