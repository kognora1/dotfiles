#version 300 es
precision mediump float;
in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;
void main() {
    vec4 color = texture(tex, v_texcoord);
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float sat = maxC - minC;
    float vibrance = 0.8;
    float boost = vibrance * (1.0 - sat);
    color.rgb = mix(vec3(luma), color.rgb, 1.0 + boost);
    fragColor = color;
}
