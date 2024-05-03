// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

#version 460
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTexCoord;
layout (location = 3) in vec3 aNormal;

out vec3 VertexColor; 
out vec2 TexCoord; 
out vec3 Normal;

out vec3 VertexPos;

uniform mat4 m_transform;
uniform mat4 m_viewMatrix;
uniform mat4 m_projMatrix;


// https://learnopengl.com/Getting-started/Shaders

void main() {
    gl_Position = m_projMatrix * m_viewMatrix * m_transform * vec4(aPos, 1.0);
    // gl_Position = m_projMatrix * m_viewMatrix * (vec4(aPos, 1.0));
    // gl_Position = m_projMatrix * (m_transform * vec4(aPos, 1.0));
    // gl_Position = m_viewMatrix * (m_transform * vec4(aPos, 1.0));
    // gl_Position = (m_transform * vec4(aPos, 1.0));
    VertexColor = aColor;
    TexCoord = aTexCoord;
    Normal = aNormal;

    VertexPos = (m_transform * vec4(aPos, 1.0)).xyz;
}

