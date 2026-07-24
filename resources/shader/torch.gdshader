shader_type spatial;

render_mode unshaded, cull_back;

uniform float noise_scale = 4.0;
uniform float speed = 2.5;
uniform float emission_strength = 8.0;

void fragment() {
	float t = TIME * speed;

	vec2 uv = UV * noise_scale;

	float n =
		sin(uv.x * 8.0 + t) * 0.25 +
		sin(uv.y * 10.0 - t * 1.3) * 0.25 +
		sin((uv.x + uv.y) * 12.0 + t * 0.7) * 0.25 +
		sin(length(uv - 0.5) * 20.0 - t * 3.0) * 0.25;

	n = n * 0.5 + 0.5;

	float edge = smoothstep(0.2, 0.9, 1.0 - length(UV - vec2(0.5)) * 1.8);

	vec3 inner = vec3(1.0, 0.95, 0.4);
	vec3 mid = vec3(1.0, 0.45, 0.05);
	vec3 outer = vec3(0.8, 0.05, 0.0);

	vec3 color = mix(outer, mid, n);
	color = mix(color, inner, edge);

	ALBEDO = color * 0.2;
	EMISSION = color * emission_strength;
}