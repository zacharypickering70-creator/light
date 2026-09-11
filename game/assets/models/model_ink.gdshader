shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 cloth_tint : source_color = vec4(1.0);
varying float facet_light;
void vertex() {
 vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
 float sun = max(dot(world_normal, normalize(vec3(-0.6, 1.0, -0.7))), 0.0);
 facet_light = 0.52 + floor(sun * 4.0) * 0.12;
}
void fragment() {
 ALBEDO = COLOR.rgb * cloth_tint.rgb * facet_light;
 ROUGHNESS = 1.0;
}
