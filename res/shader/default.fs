#version 460
out vec4 FRAG_COLOR;

in vec3 COLOR;
in vec2 UV;

uniform sampler2D Texture0;
// uniform vec2 v_screenSize; // unpure

void main() {
    // float aspect = v_screenSize.x / v_screenSize.y; // unpure
    // vec2 uv = TexCoord;
    // uv.x *= aspect;
    // uv.x += (1.0 - aspect) / 2.0;
    // FragColor = texture(Texture0, uv) * vec4(VertexColor, 1.0);
    // til here
    FRAG_COLOR = texture(Texture0, UV) * vec4(COLOR, 1.0);
}

