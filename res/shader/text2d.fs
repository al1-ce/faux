// SPDX-FileCopyrightText: (C) 2024 Faux Developers <aartificial.dev@gmail.com>
// SPDX-FileCopyrightText: (C) 2024 Faux Contributors
// SPDX-License-Identifier: GPL-3.0-or-later

#version 430
in vec2 TexCoords; // TODO: rename to UV?
out vec4 FragColor; // TODO: rename to COLOR or ALBEDO

uniform sampler2D s_text;
uniform vec4 v_color;
uniform vec2 v_texsize;

void main() {
    float outline = 0.0;

    // TODO outline
    // float line_size = 1.5;
    // vec2 pixel_size = 1.0 / v_texsize;
    // vec2 size = pixel_size * line_size;

	// float outline = texture(s_text, uv + vec2(-size.x, 0.0)).r;
	// outline += texture(s_text, uv + vec2(0.0, size.y)).r;
	// outline += texture(s_text, uv + vec2(size.x, 0.0)).r;
	// outline += texture(s_text, uv + vec2(0.0, -size.y)).r;
	// outline += texture(s_text, uv + vec2(-size.x, size.y)).r;
	// outline += texture(s_text, uv + vec2(size.x, size.y)).r;
	// outline += texture(s_text, uv + vec2(-size.x, -size.y)).r;
	// outline += texture(s_text, uv + vec2(size.x, -size.y)).r;
	// outline = min(outline, 1.0);


    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(s_text, TexCoords).r);
    FragColor = mix(v_color * sampled, vec4(0.0, 0.0, 0.0, 1.0), outline - sampled.a); //
}

