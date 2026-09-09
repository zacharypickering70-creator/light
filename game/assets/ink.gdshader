shader_type spatial;
render_mode diffuse_toon, specular_disabled;
uniform vec4 ink_color : source_color = vec4(0.25, 0.25, 0.23, 1.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float grain = hash(floor(world_pos.xz * 85.0 + world_pos.y * 40.0));
 float stroke = sin(world_pos.x * 24.0 + world_pos.z * 19.0 + world_pos.y * 37.0);
 ALBEDO = pow(ink_color.rgb, vec3(2.2)) * (0.88 + 0.12 * grain) * (0.97 + 0.03 * stroke);
 ROUGHNESS = 1.0;
}
