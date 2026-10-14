class_name IconButton
extends Control
## Botão quadrado pequeno com ícone desenhado em código (pausa, bolsa, missões, mapa).

signal pressed

var kind := ""
static var _art := {}
var _down := false


static func make(icon_kind: String, side := 24.0) -> IconButton:
	var b := IconButton.new()
	b.kind = icon_kind
	b.custom_minimum_size = Vector2(side, side)
	return b


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		elif _down:
			_down = false
			pressed.emit()
		queue_redraw()
		accept_event()


func _draw() -> void:
	var path := "res://assets/ui/botoes/quad_%s_%s.png" % [kind, "pressionado" if _down else "normal"]
	if not _art.has(path):
		# Guarda a textura: carregada só dentro do _draw ela é liberada e sai branca.
		_art[path] = load(path) if ResourceLoader.exists(path) else null
	if _art[path]:
		draw_texture_rect(_art[path], Rect2(Vector2.ZERO, size), false)
		return
	var rect := Rect2(Vector2.ZERO, size - Vector2(0, 2))
	var style := UiKit.button_style(Color(0.3, 0.17, 0.08, 0.95) if _down else Color(0.2, 0.12, 0.07, 0.88), _down)
	if _down:
		rect.position.y += 2
	draw_style_box(style, rect)
	# Brilho na parte de cima.
	draw_rect(Rect2(rect.position + Vector2(3, 3), Vector2(rect.size.x - 6, 1)), Color(1, 0.85, 0.55, 0.25))
	var c := rect.get_center()
	var s := size.x / 24.0
	var ink := UiKit.TEXT
	match kind:
		"pausa":
			draw_rect(Rect2(c + Vector2(-5, -6) * s, Vector2(3.5, 12) * s), ink)
			draw_rect(Rect2(c + Vector2(1.5, -6) * s, Vector2(3.5, 12) * s), ink)
		"menu":
			for i in 3:
				draw_rect(Rect2(c + Vector2(-6, -5 + i * 4.5) * s, Vector2(12, 2) * s), ink)
		"bolsa":
			draw_rect(Rect2(c + Vector2(-6, -2) * s, Vector2(12, 9) * s), Color(0.75, 0.5, 0.25))
			draw_rect(Rect2(c + Vector2(-6, -2) * s, Vector2(12, 9) * s), ink, false, 1.0)
			draw_arc(c + Vector2(0, -3) * s, 3.5 * s, PI, TAU, 10, ink, 1.5)
		"missoes":
			draw_rect(Rect2(c + Vector2(-5, -7) * s, Vector2(10, 14) * s), Color(0.95, 0.85, 0.6))
			for i in 3:
				draw_rect(Rect2(c + Vector2(-3, -4 + i * 3.5) * s, Vector2(6, 1.2) * s), Color(0.4, 0.25, 0.15))
		"mapa":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -5) * s, c + Vector2(-2, -7) * s, c + Vector2(2, -5) * s,
				c + Vector2(7, -7) * s, c + Vector2(7, 5) * s, c + Vector2(2, 7) * s, c + Vector2(-2, 5) * s, c + Vector2(-7, 7) * s]), Color(0.6, 0.8, 0.5))
			draw_circle(c + Vector2(1, -1) * s, 1.8 * s, Color(0.9, 0.2, 0.2))
