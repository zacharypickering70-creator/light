shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 water_point;
void vertex() { water_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 float wave = sin(water_point.x * 3.6 + water_point.z * 1.2 + TIME * 0.65);
 float crossing = sin(water_point.z * 5.2 - water_point.x * 0.7 - TIME * 0.42);
 float crest = smoothstep(0.91, 1.0, wave) * smoothstep(-0.3, 0.8, crossing);
 ALBEDO = vec3(0.33, 0.43, 0.40) + vec3(0.10, 0.11, 0.09) * crest;
}
