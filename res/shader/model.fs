#version 460
out vec4 FragColor;

in vec3 VertexColor; 
in vec2 TexCoord; 
in vec3 Normal; 

uniform sampler2D Texture0;
// 0 - normal, 1 - black, 2 - normal map, 3 - depth
uniform int uDrawMode;
uniform vec3 uClearCol;

in vec3 VertexPos;

uniform vec3 uCameraPos;
uniform float uRenderDistance;

float near = 0.1; 
  
float LinearizeDepth(float depth) {
    float far = uRenderDistance; 
    float z = depth * 2.0 - 1.0; // back to NDC 
    return (2.0 * near * far) / (far + near - z * (far - near));	
}

void drawDepth() {             
    float depth = LinearizeDepth(gl_FragCoord.z) / uRenderDistance; // divide by far for demonstration
    FragColor = vec4(vec3(depth), 1.0);
}

void drawBlack() {
    FragColor = vec4(vec3(0.0), 1.0);
} 

void drawNormals() {
    FragColor.rgb = (Normal * 0.5) + 0.5;
    FragColor.a = 1.0f;
}

void drawNormal() {
    float depth = distance(uCameraPos, VertexPos) / uRenderDistance;
    // depth = depth * 0.5 + 0.5;
    depth = max(0.0, min(1.0, depth));
    depth = smoothstep(0.0, 1.0, depth);
    vec4 shading = vec4(vec3(max(0.4, dot(Normal, vec3(0.2, 1.0, 0.0)) * 0.5 + 0.5)), 1.0);
    vec4 texColor = texture(Texture0, TexCoord);
    vec4 vertColor = vec4(VertexColor, 1.0);
    FragColor = mix(texColor * shading * vertColor, vec4(uClearCol, 1.0), depth);
}

void main() {
    switch (uDrawMode) {
        case 1: drawBlack(); return;
        case 2: drawDepth(); return;
        case 3: drawNormals(); return;
        default: drawNormal();
    }
} 

/* ------------------------------- SEAMS TEXT ------------------------------- */


/* ------------------------------- DEPTH VIEW ------------------------------- */

