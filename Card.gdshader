shader_type canvas_item;

uniform float corner : hint_range(0.0, 64.0) = 24.0;  // raio das bordas
uniform float border : hint_range(0.0, 8.0) = 2.0;    // espessura da borda
uniform vec4 border_color : source_color = vec4(0.1, 0.1, 0.1, 1.0); // cor da borda

// NOVO — background color
//uniform vec4 background_color : source_color = vec4(0.15, 0.15, 0.15, 0.0);
//uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 background_color : source_color = vec4(0.505, 0.231, 0.0, 0.0);



void fragment() {
    // tamanho da textura
    ivec2 tex_size = textureSize(TEXTURE, 0);
    vec2 size = vec2(tex_size);
    vec2 pos = UV * size;

    // cálculo dos cantos arredondados
    vec2 half_size = size * 0.5 - vec2(corner);
    vec2 q = abs(pos - size * 0.5) - half_size;
    float dist = length(max(q, vec2(0.0))) - corner;

    // cor da textura original
    vec4 tex = texture(TEXTURE, UV);

    // descarta pixels fora do raio
    if (dist > 0.0) {
        discard;
    }

	// mistura textura com fundo
    vec4 base = mix(background_color, tex, tex.a);

    // mistura da borda
    if (dist > -border) {
        float t = clamp((-dist) / border, 0.0, 1.0);
        COLOR = mix(border_color, base, t);
    } else {
        COLOR = base;
    }
}
