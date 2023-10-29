#version 460 core
layout (location = 0) in vec3 aPos;

out vec3 TexCoords;

uniform mat4 m_projMatrix;
uniform mat4 m_viewMatrix;

void main() {
    TexCoords = aPos;
    vec4 pos = m_projMatrix * m_viewMatrix * vec4(aPos, 1.0);
    // gl_Position = pos.xyww;
    gl_Position = pos;
}  

