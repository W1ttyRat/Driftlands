shader_type canvas_item;
// Hover highlight: paints the sprite's edge pixels white.
float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
	return texture(tex, uv).a;
}
void fragment() {
	vec2 p = TEXTURE_PIXEL_SIZE;
	float around = alpha_at(TEXTURE, UV + vec2(p.x, 0.0)) * alpha_at(TEXTURE, UV - vec2(p.x, 0.0))
		* alpha_at(TEXTURE, UV + vec2(0.0, p.y)) * alpha_at(TEXTURE, UV - vec2(0.0, p.y));
	if (COLOR.a > 0.0 && around < 1.0) {
		COLOR.rgb = vec3(1.0);
	}
}
