shader_type spatial;
render_mode unshaded;
uniform vec4 paper_tint : source_color = vec4(0.88, 0.86, 0.80, 1.0);
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f); return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_pos.xz;
 float grain = hash(floor(p*80.0));
 float wash = noise(p*0.095)*0.62 + noise(p*0.38)*0.25 + noise(p*1.2)*0.13;
 float brush = smoothstep(0.48, 0.64, noise(p*vec2(0.28,0.07)))*0.065;
 float fibers = sin(p.x*310.0 + noise(p*2.0)*10.0)*0.009;
 ALBEDO = paper_tint.rgb - vec3(wash*0.14 + brush + grain*0.028 + fibers);
}
