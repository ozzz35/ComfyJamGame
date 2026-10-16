shader_type canvas_item;
render_mode blend_add;

uniform float speed : hint_range(0.0, 60.0) = 22.0;
uniform float block_scale : hint_range(1.0, 200.0) = 64.0;
uniform float strength : hint_range(0.0, 3.0) = 1.35;
uniform float scroll_down : hint_range(0.0, 0.4) = 0.40;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash1(float p) {
	return fract(sin(p * 127.1) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float drift = TIME * scroll_down;
	vec2 suv = vec2(uv.x, fract(uv.y + drift));
	float t = TIME * speed;

	float tick = floor(t * 3.5);
	float burst_on = step(0.35, hash1(tick * 0.17));
	float micro_tick = floor(t * 14.0);
	float row_flicker = step(0.55, hash(vec2(micro_tick, floor(suv.y * 12.0))));

	float row = floor(suv.y * block_scale);
	float row_gate = step(0.45, hash(vec2(row, floor(t * 1.8))));
	float gate = burst_on * max(row_gate, row_flicker);

	float shift_row = floor(suv.y * block_scale * 2.2);
	float shift = (hash(vec2(shift_row, t * 2.3)) - 0.5) * 0.11 * gate;
	vec2 guv = suv + vec2(shift, 0.0);

	float scan_phase = suv.y * 900.0 - t * 85.0 - drift * 1200.0;
	float scan = sin(scan_phase) * 0.11;
	float scan2 = sin(scan_phase * 0.37 + t * 40.0) * 0.06 * gate;

	float n = hash(guv * 1200.0 + vec2(t * 3.1, t * 2.4));
	float spark = step(0.92, hash(guv * 400.0 + vec2(t * 5.0, micro_tick))) * gate;

	vec3 col;
	col.r = hash(guv * 900.0 + vec2(t * 2.7, 0.0));
	col.g = hash(guv * 900.0 + vec2(0.0, t * 2.1));
	col.b = hash(guv * 900.0 + vec2(-t * 1.9, t * 2.5));
	col = (col - 0.5) * 0.55 + vec3(n * 0.35) + scan + scan2;
	col += vec3(spark * 0.9);
	col *= gate * 1.1 + 0.04;

	COLOR = vec4(col * strength, 1.0);
}
