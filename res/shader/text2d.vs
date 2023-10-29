#version 430
layout (location = 0) in vec4 vertex; // <vec2 pos, vec2 tex>
out vec2 TexCoords;

uniform mat4 m_projection;

void main() {
    // gl_Position = vec4(vertex.xy, 0.0, 1.0);
    gl_Position = m_projection * vec4(vertex.xy, 0.0, 1.0);
    
    TexCoords = vertex.zw; // value is interpolated so it seems like UV
}  

