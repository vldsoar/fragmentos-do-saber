shader_type canvas_item;

uniform sampler2D mask_texture;
uniform float alpha_threshold = 0.8; // valor ideal para sua imagem

void fragment() {
    vec4 mask = texture(mask_texture, UV);

    // Se a moldura for opaca (alpha > threshold), descartar
    if (mask.a > alpha_threshold) {
        discard;
    }

    // Caso contrário (vidro), desenhar areia
    COLOR = COLOR;
}
