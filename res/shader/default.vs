#version 460
layout (location = 0) in vec3 VERTEX;
layout (location = 1) in vec3 ALBEDO;
layout (location = 2) in vec2 TEX_COORD;

out vec3 COLOR;
out vec2 UV;

// https://learnopengl.com/Getting-started/Shaders

void main() {
    // gl_Position = vec4(VERTEX, 1.0);
    UV = TEX_COORD;
    COLOR = ALBEDO;
}

