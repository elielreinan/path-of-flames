class_name CompareMark
extends Control
## Sinal de comparação com o equipamento em uso: seta verde para cima (melhor),
## seta vermelha para baixo (pior) ou traço cinza (igual).

const BETTER := Color(0.35, 0.9, 0.4)
const WORSE := Color(0.95, 0.35, 0.3)
const SAME := Color(0.7, 0.7, 0.7)

var delta := 0:
	set(value):
		delta = value
		queue_redraw()


static func make(value: int, side := 10.0) -> CompareMark:
	var mark := CompareMark.new()
	mark.delta = value
	mark.custom_minimum_size = Vector2(side, side)
	mark.size = Vector2(side, side)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark


static func color_for(value: int) -> Color:
	return BETTER if value > 0 else WORSE if value < 0 else SAME


## Desenha o sinal num CanvasItem qualquer (usado também pela grade da bolsa).
static func paint(canvas: CanvasItem, rect: Rect2, value: int) -> void:
	var c := rect.get_center()
	var h := rect.size.y * 0.42
	var w := rect.size.x * 0.42
	var col := color_for(value)
	var shadow := Color(0, 0, 0, 0.8)
	if value == 0:
		canvas.draw_rect(Rect2(c - Vector2(w, 1.5), Vector2(w * 2, 3)).grow(1), shadow)
		canvas.draw_rect(Rect2(c - Vector2(w, 1.5), Vector2(w * 2, 3)), col)
		return
	var dir := -1.0 if value > 0 else 1.0
	var pts := PackedVector2Array([c + Vector2(0, h * dir), c + Vector2(w, -h * dir * 0.6), c + Vector2(-w, -h * dir * 0.6)])
	var big := PackedVector2Array([c + Vector2(0, (h + 1.5) * dir), c + Vector2(w + 1.5, -(h + 1) * dir * 0.6), c + Vector2(-w - 1.5, -(h + 1) * dir * 0.6)])
	canvas.draw_colored_polygon(big, shadow)
	canvas.draw_colored_polygon(pts, col)


func _draw() -> void:
	CompareMark.paint(self, Rect2(Vector2.ZERO, size), delta)
