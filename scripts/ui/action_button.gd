class_name ActionButton
extends Control
## Botão de toque redondo que dispara uma ação do Input Map.
## Fica preso a um canto da tela por `anchor_offset` (centro do botão) e cresce com as Configurações.

var action := ""
var label := ""
## Desenho do ícone: "espada", "fogo" ou "falar".
var icon := ""
var color := Color(1, 0.5, 0.1)
var base_radius := 22.0
## Posição do centro em relação ao canto inferior direito, antes da escala.
var anchor_offset := Vector2.ZERO
## Quando falso o botão aparece apagado (por exemplo, FOGO antes de aprender a magia).
var enabled := true:
	set(value):
		enabled = value
		queue_redraw()
## Devolve a fração de recarga que falta (0 = pronto). Vazio = sem recarga.
var cooldown_source := Callable()
## Para o botão de atalho: devolve o id do item mostrado no botão.
var item_source := Callable()
## Brilho pulsando em volta quando o golpe especial está pronto.
var ready_glow := false:
	set(value):
		ready_glow = value
		queue_redraw()
var _touch_index := -1
var _last_cooldown := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Recebe a soltura do dedo mesmo com o jogo pausado (diálogo, menu), senão o controle fica preso.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.changed.connect(_layout)
	_layout()


var _item_icon: TextureRect
var _item_shown := ""


func _update_item_icon() -> void:
	var id: String = item_source.call()
	if id == _item_shown and _item_icon:
		return
	_item_shown = id
	if _item_icon == null:
		_item_icon = TextureRect.new()
		_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_item_icon)
	var item: Dictionary = Data.items.get(id, {})
	_item_icon.texture = load(item.sprite) if item.has("sprite") else null
	_layout_item_icon()


func _layout_item_icon() -> void:
	if _item_icon:
		var side := radius() * 0.9
		_item_icon.size = Vector2(side, side)
		_item_icon.position = size / 2.0 - Vector2(side, side) / 2.0 - Vector2(0, radius() * 0.08)


func radius() -> float:
	return base_radius * Settings.button_scale()


func _layout() -> void:
	var r := radius()
	size = Vector2(r, r) * 2.0
	position = anchor_offset * Settings.button_scale() - Vector2(r, r)
	_layout_item_icon()
	queue_redraw()


func _process(_delta: float) -> void:
	if item_source.is_valid():
		_update_item_icon()
	var cd := _cooldown()
	if cd > 0.0 or _last_cooldown > 0.0 or item_source.is_valid() or ready_glow:
		queue_redraw()
	_last_cooldown = cd


func _cooldown() -> float:
	return clampf(float(cooldown_source.call()), 0.0, 1.0) if cooldown_source.is_valid() else 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release()


func _release() -> void:
	if _touch_index != -1:
		_touch_index = -1
		Input.action_release(action)
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or get_tree().paused:
		_release()
		return
	if event is InputEventScreenTouch and event.canceled:
		_release()
	elif event is InputEventScreenTouch:
		var center := global_position + size / 2.0
		if event.pressed and _touch_index == -1 and event.position.distance_to(center) <= radius() + 6.0:
			_touch_index = event.index
			Input.action_press(action)
			get_viewport().set_input_as_handled()
			queue_redraw()
		elif not event.pressed and event.index == _touch_index:
			_release()


## Arte dos botões (fio de Artes, assets/ui/botoes): ícone do jogo -> nome do arquivo.
const ART := {"espada": "golpe", "fogo": "fogo", "especial": "especial", "falar": "falar", "montar": "montar", "item": "item"}
static var _art_cache := {}


static func _art(name: String) -> Texture2D:
	if not _art_cache.has(name):
		var path := "res://assets/ui/botoes/%s.png" % name
		_art_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _art_cache[name]


func _draw() -> void:
	var art_id: String = ART.get(icon, "")
	var state := "desabilitado" if not enabled else ("pressionado" if _touch_index != -1 else "normal")
	var tex: Texture2D = null
	if art_id == "item" and item_source.is_valid() and Data.items.has(str(item_source.call())):
		# Com item no atalho: moldura verde vazia; o ícone do item vai por cima.
		tex = _art("moldura_normal_verde_" + ("pressionado" if state == "pressionado" else "normal"))
	elif art_id != "":
		tex = _art("acao_%s_%s" % [art_id, state])
	if tex == null:
		_draw_vector()
		return
	var r := radius()
	var center := size / 2.0
	if ready_glow and enabled:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 130.0)
		draw_circle(center, r + 3.0 + pulse * 2.0, Color(1.0, 0.6, 0.2, 0.25 + 0.25 * pulse))
	var alpha := minf(Settings.controls_alpha() + 0.45, 1.0)
	draw_texture_rect(tex, Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1, 1, 1, alpha))
	var s := r / 22.0
	if art_id == "item":
		var id: String = item_source.call() if item_source.is_valid() else ""
		if id != "" and Data.items.has(id):
			var count := str(GameState.item_count(id))
			var f := get_theme_default_font()
			var fs := int(8 * s)
			draw_string_outline(f, center + Vector2(r * 0.3, r * 0.75), count, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
			draw_string(f, center + Vector2(r * 0.3, r * 0.75), count, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	_draw_cooldown(center, r * 0.86)


func _draw_cooldown(center: Vector2, r: float) -> void:
	# Recarga: fatia escura que diminui no sentido horário.
	var cd := _cooldown()
	if cd > 0.0:
		var points := PackedVector2Array([center])
		var steps := 24
		for i in steps + 1:
			var a := -PI / 2.0 + TAU * cd * i / steps
			points.append(center + Vector2.from_angle(a) * r)
		draw_colored_polygon(points, Color(0, 0, 0, 0.55))


## Desenho antigo em código (quando falta a arte).
func _draw_vector() -> void:
	var r := radius()
	var center := size / 2.0
	var pressed := _touch_index != -1
	var alpha := Settings.controls_alpha() + (0.3 if pressed else 0.15)
	if not enabled:
		alpha *= 0.5
	var fill := color if enabled else Color(0.4, 0.4, 0.4)
	if ready_glow and enabled:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 130.0)
		draw_circle(center, r + 4.0 + pulse * 2.0, Color(1.0, 0.6, 0.2, 0.25 + 0.25 * pulse))
	# Botão em relevo: sombra embaixo, aro de bronze, face com luz em cima. Apertado, afunda.
	var a := minf(alpha + 0.15, 1.0)
	if not pressed:
		draw_circle(center + Vector2(0, 3), r, Color(0, 0, 0, a * 0.45))
	else:
		center += Vector2(0, 2)
	draw_circle(center, r, Color(0.16, 0.09, 0.05, a))
	var rim := UiKit.BORDER if enabled else Color(0.55, 0.5, 0.45)
	draw_circle(center, r - 1.5, Color(rim.darkened(0.35), a))
	draw_arc(center, r - 2.0, PI * 1.05, PI * 1.95, 20, Color(rim.lightened(0.3), a), 1.5)
	var face := r - 4.0
	draw_circle(center, face, Color(fill.darkened(0.45), a))
	draw_circle(center + Vector2(0, -face * 0.12), face * 0.88, Color(fill.darkened(0.1 if not pressed else 0.3), a))
	draw_arc(center + Vector2(0, -face * 0.12), face * 0.7, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, a * 0.3), maxf(face * 0.12, 1.5))
	var s := r / 22.0
	_draw_icon(center + Vector2(0, -3 * s) + Vector2(0, 1.5 * s), s, Color(0, 0, 0, minf(alpha, 0.8)), fill)
	_draw_icon(center + Vector2(0, -3 * s), s, Color(1, 1, 1, minf(alpha + 0.4, 1.0)), fill)
	var ink := Color(1, 1, 1, minf(alpha + 0.4, 1.0))
	if icon == "item":
		var id: String = item_source.call() if item_source.is_valid() else ""
		if id != "" and Data.items.has(id):
			var count := str(GameState.item_count(id))
			var f := get_theme_default_font()
			var fs := int(8 * s)
			draw_string_outline(f, center + Vector2(r * 0.3, r * 0.55), count, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color.BLACK)
			draw_string(f, center + Vector2(r * 0.3, r * 0.55), count, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	_draw_label(center, r, s, alpha, ink)


func _draw_icon(c: Vector2, s: float, ink: Color, fill: Color) -> void:
	match icon:
		"especial":
			# Chama no meio de uma explosão de raios.
			for i in 8:
				var dir := Vector2.from_angle(TAU * i / 8.0)
				draw_line(c + dir * 6.0 * s, c + dir * 10.0 * s, ink, 1.5 * s)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6) * s, c + Vector2(4, 1) * s, c + Vector2(2, 5) * s,
				c + Vector2(-2, 5) * s, c + Vector2(-4, 1) * s]), ink)
		"montar":
			# Ferradura.
			draw_arc(c + Vector2(0, -1) * s, 6.0 * s, PI * 0.15 + PI, PI * 1.85 + PI, 12, ink, 3.0 * s)
			draw_arc(c + Vector2(0, 1) * s, 6.0 * s, -PI * 0.1, PI * 1.1, 12, ink, 3.0 * s)
		"item":
			var id: String = item_source.call() if item_source.is_valid() else ""
			if id == "" or not Data.items.has(id):
				draw_arc(c, 6 * s, 0, TAU, 16, ink, 1.5)
		"espada":
			draw_line(c + Vector2(-7, 7) * s, c + Vector2(7, -7) * s, ink, 3.0 * s)
			draw_line(c + Vector2(-8, 2) * s, c + Vector2(-2, 8) * s, ink, 2.5 * s)
		"fogo":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9) * s, c + Vector2(6, 2) * s, c + Vector2(3, 7) * s,
				c + Vector2(-3, 7) * s, c + Vector2(-6, 2) * s]), ink)
			draw_circle(c + Vector2(0, 3) * s, 2.5 * s, Color(fill, 1.0))
		"falar":
			draw_rect(Rect2(c + Vector2(-8, -6) * s, Vector2(16, 10) * s), ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 4) * s, c + Vector2(2, 4) * s, c + Vector2(-4, 9) * s]), ink)
			for i in 3:
				draw_circle(c + Vector2(-4 + i * 4, -1) * s, 1.2 * s, Color(fill, 1.0))


func _draw_label(center: Vector2, r: float, s: float, alpha: float, ink: Color) -> void:
	var font := get_theme_default_font()
	var font_size := int(round(7 * s))
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string_outline(font, center + Vector2(-text_size.x / 2.0, r * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, 3, Color(0, 0, 0, minf(alpha + 0.3, 1.0)))
	draw_string(font, center + Vector2(-text_size.x / 2.0, r * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, ink)
	_draw_cooldown(center, r)
