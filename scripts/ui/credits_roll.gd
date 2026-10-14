extends Control
## Créditos curtos subindo pela tela. Segurar acelera; tocar no fim fecha; "Pular" encerra.

signal finished

const GOLD := Color(1.0, 0.8, 0.3)
const SOFT := Color(0.95, 0.9, 0.8)
const DIM := Color(0.7, 0.62, 0.52)
const SPEED := 20.0
const FAST := 5.0

var _content: VBoxContainer
var _scroll := 0.0
var _holding := false
var _time := 0.0
var _end_time := -1.0
var _done := false
var _skip: Button
var _motes: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Som.music("final", 2.5)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 24:
		_motes.append(Vector3(randf(), randf(), randf_range(0.4, 1.0)))
	var vs := get_viewport_rect().size
	var width := minf(vs.x - 40.0, 420.0)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 2)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.position = Vector2((vs.x - width) / 2.0, vs.y)
	_content.size = Vector2(width, 0)
	add_child(_content)
	_line("Path of Flames", 26, GOLD, width, 6)
	_line("A Lenda das Sete Chamas", 9, DIM, width)
	_space(40)
	_role("Ideia e direção", "Eliel Reinan", width)
	_role("Programação, roteiro e arte provisória", "Claude", width)
	_role("Personagens, criaturas e cenário (modificados)", "Sunnyside World, de Daniel Diggle", width)
	_role("Músicas e efeitos sonoros", "compostos para o jogo por Claude (CC0)", width)
	_role("Sons de interface", "Kenney (www.kenney.nl, CC0)", width)
	_space(26)
	_line("Inspirado no espírito dos RPGs clássicos online", 9, SOFT, width)
	_space(30)
	var total: int = Data.secrets.size()
	if total > 0:
		_line("Segredos encontrados: %d/%d" % [GameState.secrets_found(), total], 10, GOLD, width)
		_space(6)
	_line("Nível %d  ·  Honra %d" % [GameState.level, GameState.honra], 9, DIM, width)
	_space(50)
	_line("Obrigado por jogar!", 16, Color(1, 0.97, 0.9), width, 5)
	_skip = UiKit.button("Pular", 8)
	_skip.pressed.connect(_close)
	add_child(_skip)


func _line(text: String, size: int, color: Color, width: float, outline := 3) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(l)


func _role(role: String, who: String, width: float) -> void:
	_line(role.to_upper(), 8, DIM, width)
	_line(who, 13, SOFT, width, 4)
	_space(14)


func _space(h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(c)


func _process(delta: float) -> void:
	_time += delta
	var vs := get_viewport_rect().size
	_skip.reset_size()
	_skip.position = Vector2(vs.x - _skip.size.x - 10.0, 8.0)
	if _end_time < 0.0:
		_scroll += delta * SPEED * (FAST if _holding else 1.0)
	_content.position.y = vs.y + 4.0 - _scroll
	var last: Control = _content.get_child(_content.get_child_count() - 1)
	var cy := _content.position.y + last.position.y + last.size.y / 2.0
	if _end_time < 0.0 and cy <= vs.y * 0.5:
		_end_time = _time
	elif _end_time >= 0.0 and _time - _end_time > 4.0:
		_close()
	for c in _content.get_children():
		var y: float = _content.position.y + c.position.y + c.size.y / 2.0
		c.modulate.a = clampf(minf(y / 30.0 - 0.3, (vs.y - y) / 30.0), 0.0, 1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_holding = event.pressed
		accept_event()
		if event.pressed and _end_time >= 0.0 and _time - _end_time > 0.8:
			_close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("ui_accept"):
		_holding = event.is_pressed()
		get_viewport().set_input_as_handled()


func _close() -> void:
	if _done:
		return
	_done = true
	var out := create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_property(_content, "modulate:a", 0.0, 1.0)
	out.parallel().tween_property(_skip, "modulate:a", 0.0, 0.3)
	await out.finished
	# Deixa a tela preta do mundo ligada: a troca de mapa que vem depois não mostra a casa por um instante.
	var world: Node = get_tree().root.get_node_or_null("World")
	var fade = world.get("_fade") if world else null
	if fade is ColorRect:
		fade.color.a = 1.0
	finished.emit()
	queue_free()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.03, 0.02))
	for i in 8:
		draw_rect(Rect2(0, h * (0.6 + i * 0.05), w, h * 0.05 + 1), Color(0.3, 0.14, 0.04, 0.03 * (i + 1)))
	for m in _motes:
		var y := fmod(m.y - _time * 0.04 * m.z + 3.0, 1.0)
		var p := Vector2(m.x * w + sin(_time * 1.3 + m.x * 30.0) * 6.0, y * h)
		draw_circle(p, 0.5 + m.z, Color(1.0, 0.65, 0.25, 0.5 * m.z))
