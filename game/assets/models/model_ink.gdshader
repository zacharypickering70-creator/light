shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 cloth_tint : source_color = vec4(1.0);
varying float facet_light;
varying vec3 local_point;
void vertex() {
 local_point = VERTEX;
 vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
 float sun = max(dot(world_normal, normalize(vec3(-0.6, 1.0, -0.7))), 0.0);
 facet_light = 0.58 + smoothstep(0.12, 0.82, sun) * 0.38;
}
void fragment() {
 float weave = 0.97 + 0.03 * sin(local_point.y * 37.0 + local_point.x * 21.0);
 float contour = 0.82 + 0.18 * smoothstep(0.0, 0.40, abs(dot(normalize(NORMAL), normalize(VIEW))));
 ALBEDO = COLOR.rgb * cloth_tint.rgb * facet_light * weave * contour;
 ROUGHNESS = 1.0;
}
