#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
  mat4 qt_Matrix;
  float qt_Opacity;
  float w;
  float h;
  float r;
  float offset;
  vec4 bg1;
  vec4 bg2;
  vec4 bg3;
};

float rounded_rect_sdf(vec2 p, vec2 size, float radius) {
  vec2 q = abs(p - size * 0.5) - size * 0.5 + radius;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0) - radius;
}

vec4 rainbow_diagonal_band(float wh_ratio) {
  float d = qt_TexCoord0.x * wh_ratio + qt_TexCoord0.y;
  float up_limit = wh_ratio + 1;
  float t = mod(d - offset, up_limit);
  float aa = max(fwidth(t) * 0.5, 1e-3);

  float m1 = smoothstep(-aa, aa, t) * (1 - smoothstep(0.33 * up_limit - aa, 0.33 * up_limit + aa, t));
  float m2 = smoothstep(0.33 * up_limit - aa, 0.33 * up_limit + aa, t) * (1 - smoothstep(0.66 * up_limit - aa, 0.66 * up_limit + aa, t));

  vec4 col = bg1;
  col = mix(col, bg2, m1);
  col = mix(col, bg3, m2);

  return col;
}

void main() {
  vec2 size = vec2(w, h);
  vec2 pos = qt_TexCoord0 * size;
  float dist = rounded_rect_sdf(pos, size, r);
  float alpha = (1.0 - smoothstep(-1, 1, dist)) * qt_Opacity;

  float wh_ratio = size.x / size.y;

  fragColor = rainbow_diagonal_band(wh_ratio) * alpha;
}