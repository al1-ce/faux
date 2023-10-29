#version 460 core
out vec4 FragColor;

in vec3 TexCoords;

uniform samplerCube skybox;

void main() {    
    // FragColor = texture(skybox, TexCoords);
    FragColor = vec4(0.33, 0.53, 0.7, 1);
}

