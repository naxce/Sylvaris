#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    vec3 lms = mat3(17.8824, 3.45565, 0.0299566, 43.5161, 27.1554, 0.184309, 4.11935, 3.86714, 1.46709) * c.rgb;
    vec3 s = vec3(lms.x, 0.494207 * lms.x + 1.24827 * lms.z, lms.z);
    vec3 seen = mat3(0.0809444479, -0.0102485335, -0.000365296938, -0.130504409, 0.0540193266, -0.00412161469, 0.116721066, -0.113614708, 0.693511405) * s;
    vec3 err = c.rgb - seen;
    vec3 fix = vec3(0.0, 0.7 * err.r + err.g, 0.7 * err.r + err.b);
    fragColor = vec4(clamp(c.rgb + fix, 0.0, 1.0), c.a);
}
