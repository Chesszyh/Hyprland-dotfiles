precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    
    // Screen aspect compensation (2560x1600 = 16:10)
    vec2 coord = (v_texcoord - vec2(0.5)) * vec2(1.6, 1.0);
    float dist = length(coord);
    
    // Cinematic abyssal vignette: crisp center, deep shadow and dried blood corner falloff
    float outerRadius = 0.94;
    float innerRadius = 0.44;
    float vignette = 1.0 - smoothstep(innerRadius, outerRadius, dist);
    
    // Deep crimson obsidian undertone in peripheral corners
    vec3 cornerTint = vec3(0.040, 0.007, 0.014);
    vec3 color = mix(cornerTint, pixColor.rgb, vignette);
    
    gl_FragColor = vec4(color, pixColor.a);
}
