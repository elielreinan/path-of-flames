shader_type canvas_item;
// Vento nas árvores: a copa balança e o pé fica parado.
uniform float forca = 1.2;
uniform float velocidade = 1.6;

void vertex() {
	float fase = MODEL_MATRIX[3].x * 0.07 + MODEL_MATRIX[3].y * 0.03;
	float rajada = 0.6 + 0.4 * sin(TIME * 0.35 + fase * 0.5);
	float topo = 1.0 - UV.y;
	VERTEX.x += sin(TIME * velocidade + fase) * forca * rajada * topo * topo * 2.0;
}
