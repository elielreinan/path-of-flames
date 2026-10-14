shader_type canvas_item;
// Ondas na água do chão assado: brilho que corre e escurece em faixas.
// Só mexe em pixels azulados, então areia, grama e casas ficam iguais.

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float azul = smoothstep(0.08, 0.22, c.b - max(c.r, c.g * 0.92));
	if (azul > 0.0) {
		vec2 p = UV / TEXTURE_PIXEL_SIZE;
		float onda = sin(p.x * 0.18 + p.y * 0.35 - TIME * 1.6) * 0.5 + 0.5;
		float onda2 = sin(p.x * 0.07 - p.y * 0.21 + TIME * 0.9) * 0.5 + 0.5;
		float brilho = pow(onda * onda2, 6.0);
		c.rgb += vec3(0.22, 0.26, 0.28) * brilho * azul;
		c.rgb *= 1.0 - 0.06 * azul * (1.0 - onda2);
	}
	COLOR = c;
}
