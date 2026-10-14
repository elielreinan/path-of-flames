extends Control
## Destinos: um quadro para cada aliado que lutou ao lado de Ifrit e um último para o próprio herói.
## Honra alta (>= 50) dá finais dourados; honra baixa, finais cinzentos e avermelhados.
## Tocar avança (os primeiros 0,6 s de cada quadro ignoram toques, para não pular sem querer).

signal finished

const GOLD := Color(1.0, 0.8, 0.3)
const GOLD_SOFT := Color(1.0, 0.93, 0.78)
const ASH := Color(0.88, 0.42, 0.34)
const ASH_SOFT := Color(0.82, 0.78, 0.74)

var _good := true
var _slides: Array = []
var _index := -1
var _time := 0.0
var _slide_time := 0.0
var _page: Control
var _busy := false
var _done := false
var _motes: Array = []
var _hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Som.music("final", 2.5)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_good = GameState.honra >= 50
	_build_slides()
	for i in 34:
		_motes.append(Vector3(randf(), randf(), randf_range(0.4, 1.0)))
	_hint = _make_label("Toque para continuar", 8, Color(_soft(), 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_hint.position = Vector2(0, get_viewport_rect().size.y - 20.0)
	_hint.size = Vector2(get_viewport_rect().size.x, 12)
	_hint.modulate.a = 0.0
	add_child(_hint)
	_next()


func _accent() -> Color:
	return GOLD if _good else ASH


func _soft() -> Color:
	return GOLD_SOFT if _good else ASH_SOFT


func _build_slides() -> void:
	if GameState.has_flag("nadia_aliada"):
		_slides.append({"retrato": "Nadia", "nome": "Nadia",
			"titulo": "Capitã da Guarda de Miraj" if _good else "A Andarilha do Deserto",
			"linhas": [
				"Nadia voltou ao oásis e assumiu o comando da guarda de Miraj.",
				"Toda manhã ensina os jovens a usar o arco do jeito que Kadir a ensinou: respirar fundo, mirar com calma e nunca soltar a flecha com raiva.",
				"Os bandidos do deserto aprenderam a dar a volta pelo oásis.",
			] if _good else [
				"Nadia não voltou para Miraj.",
				"\"Kadir nunca faria isso\" foi a última coisa que ela disse a Ifrit, sem olhar para trás.",
				"Partiu sozinha deserto adentro. Ninguém sabe que trilha ela segue agora.",
			]})
	if GameState.has_flag("bako_aliado"):
		_slides.append({"retrato": "Bako", "nome": "Bako",
			"titulo": "O Navegante Livre" if _good else "O Terror da Costa",
			"linhas": [
				"Com sua parte do tesouro, Bako comprou um navio e lhe deu o nome do irmão: Jabari.",
				"Hoje navega livre pela costa de Zahra, sem dever uma pérola a ninguém.",
				"Na proa, pendurou uma brasa de Areia Rubra, para nunca esquecer quem o trouxe de volta.",
			] if _good else [
				"Bako aprendeu com Ifrit que a força resolve tudo e que promessas valem pouco.",
				"Juntou os piratas que sobraram e se tornou o novo capitão da costa.",
				"Em Porto Coral, as mães assustam os filhos com o nome dele.",
			]})
	if GameState.has_flag("omar_aliado"):
		_slides.append({"retrato": "Omar, o Mago", "nome": "Omar, o Mago",
			"titulo": "O Guardião dos Livros" if _good else "O Cronista Amargo",
			"linhas": [
				"Omar reconstruiu a Grande Biblioteca de Qadim, pedra por pedra, livro por livro.",
				"Na estante mais alta, ao lado do Livro das Chamas, colocou um volume novo, escrito por ele mesmo:",
				"\"O Livro de Ifrit\".",
			] if _good else [
				"Omar reconstruiu a biblioteca de Qadim e escreveu a história da guerra contra Zahrak.",
				"Falou das sete chamas, de Kadir, de Nadia e de Bako.",
				"O nome de Ifrit não aparece em nenhuma página.",
			]})
	if GameState.has_flag("kadir_livre"):
		_slides.append({"retrato": "Kadir", "nome": "Kadir",
			"titulo": "O Guardião que Passou a Chama" if _good else "O Guardião que Recusou",
			"linhas": [
				"Diante da Chama Sagrada, Kadir tirou o manto de guardião e o colocou nos ombros do filho.",
				"\"Eu protegi as chamas. Você as acendeu de novo. O título é seu, Ifrit.\"",
			] if _good else [
				"Kadir guardou o manto de guardião no baú e trancou a tampa.",
				"\"Não posso passar o título a você, filho. As chamas não obedecem a quem mente.\"",
			]})
	_slides.append({"retrato": "Ifrit", "nome": "Ifrit",
		"titulo": "Guardião das Sete Chamas" if _good else "Herdeiro das Cinzas",
		"linhas": [
			"As Sete Chamas ardem em todo o reino, e o nome de Ifrit é cantado de Areia Rubra até a Cidadela.",
			"Não pelo que ele venceu, mas pelo jeito como venceu.",
			"Honra: %d" % GameState.honra,
		] if _good else [
			"As Sete Chamas ardem de novo, mas o povo baixa os olhos quando Ifrit passa.",
			"Zahrak também foi um guardião, um dia. Também achou que o fim justificava tudo.",
			"Honra: %d" % GameState.honra,
		]})


func _next() -> void:
	if _busy or _done:
		return
	_busy = true
	if _page:
		var out := create_tween()
		out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		out.tween_property(_page, "modulate:a", 0.0, 0.35)
		await out.finished
		_page.queue_free()
		_page = null
	_index += 1
	if _index >= _slides.size():
		_close()
		return
	_page = _build_page(_slides[_index])
	add_child(_page)
	_slide_time = 0.0
	_page.modulate.a = 0.0
	var t := create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(_page, "modulate:a", 1.0, 0.5)
	_busy = false


func _build_page(s: Dictionary) -> Control:
	var vs := get_viewport_rect().size
	var page := Control.new()
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.size = vs
	var card_w := minf(vs.x - 40.0, 470.0)
	var pw := 92.0
	var text_w := card_w - pw - 18.0
	var left := (vs.x - card_w) / 2.0

	# Coluna de texto (primeiro, para medir a altura e centralizar tudo).
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kicker := _make_label(s.nome.to_upper(), 9, _accent(), HORIZONTAL_ALIGNMENT_LEFT)
	col.add_child(kicker)
	var title := _make_label(s.titulo, 16, Color(1, 0.97, 0.9), HORIZONTAL_ALIGNMENT_LEFT, 5)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(text_w, 0)
	col.add_child(title)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 3)
	col.add_child(gap)
	for line in s.linhas:
		var l := _make_label(line, 9, _soft(), HORIZONTAL_ALIGNMENT_LEFT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(text_w, 0)
		if line.begins_with("Honra:"):
			l.add_theme_color_override("font_color", _accent())
		col.add_child(l)
	col.position = Vector2(left + pw + 18.0, 0)
	col.size = Vector2(text_w, 0)
	page.add_child(col)
	col.reset_size()
	var col_h := col.get_combined_minimum_size().y
	var block_h := maxf(col_h, pw + 14.0)
	var top := maxf(28.0, (vs.y - block_h) / 2.0 - 4.0)
	col.position.y = top + maxf(0.0, (block_h - col_h) / 2.0)

	# Retrato numa moldura de madeira.
	var frame := PanelContainer.new()
	var style := DialogBox.wood_style(Color(0.16, 0.1, 0.07) if _good else Color(0.12, 0.1, 0.1), 3, 4)
	style.border_color = Color(0.55, 0.35, 0.15) if _good else Color(0.35, 0.3, 0.3)
	frame.add_theme_stylebox_override("panel", style)
	frame.position = Vector2(left, top + (block_h - pw - 14.0) / 2.0)
	frame.custom_minimum_size = Vector2(pw, pw)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait := TextureRect.new()
	portrait.texture = DialogBox.portrait_for(s.retrato)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.custom_minimum_size = Vector2(pw - 8, pw - 8)
	if not _good:
		portrait.modulate = Color(0.78, 0.68, 0.66)
	frame.add_child(portrait)
	page.add_child(frame)
	var plate := _make_label("%d / %d" % [_index + 1, _slides.size()], 8, Color(_accent(), 0.8), HORIZONTAL_ALIGNMENT_CENTER)
	plate.position = Vector2(left, frame.position.y + pw + 14.0)
	plate.size = Vector2(pw, 12)
	page.add_child(plate)
	return page


func _make_label(text: String, size: int, color: Color, align: HorizontalAlignment, outline := 3) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	_time += delta
	_slide_time += delta
	var vs := get_viewport_rect().size
	_hint.position = Vector2(0, vs.y - 20.0)
	_hint.size = Vector2(vs.x, 12)
	if _done:
		return
	_hint.modulate.a = clampf((_slide_time - 0.6) * 2.0, 0.0, 1.0) * (0.6 + 0.4 * sin(_time * 3.0))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if _slide_time > 0.6:
			_next()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _slide_time > 0.6:
		get_viewport().set_input_as_handled()
		_next()


func _close() -> void:
	if _done:
		return
	_done = true
	var out := create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_property(_hint, "modulate:a", 0.0, 0.3)
	_hint.hide()
	await out.finished
	finished.emit()
	queue_free()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var base := Color(0.07, 0.045, 0.03) if _good else Color(0.06, 0.05, 0.055)
	var glow := Color(0.35, 0.18, 0.05) if _good else Color(0.3, 0.07, 0.06)
	draw_rect(Rect2(0, 0, w, h), base)
	# Brilho baixo, como uma fogueira fora da tela.
	for i in 10:
		var a := 0.05 * (i + 1) / 10.0
		draw_rect(Rect2(0, h * (0.45 + i * 0.055), w, h * 0.06), Color(glow, a * 2.0))
	# Faixas de cinema com linha fina da cor do final.
	draw_rect(Rect2(0, 0, w, 22), Color.BLACK)
	draw_rect(Rect2(0, h - 26, w, 26), Color.BLACK)
	draw_line(Vector2(0, 22), Vector2(w, 22), Color(_accent(), 0.35), 1.0)
	draw_line(Vector2(0, h - 26), Vector2(w, h - 26), Color(_accent(), 0.35), 1.0)
	# Brasas subindo (honra alta) ou cinzas caindo (honra baixa).
	for m in _motes:
		var dir := -1.0 if _good else 1.0
		var y := fmod(m.y + _time * 0.05 * m.z * dir + 3.0, 1.0)
		var p := Vector2(m.x * w + sin(_time * 1.5 + m.x * 25.0) * 8.0, y * h)
		var col := Color(1.0, 0.6 + 0.3 * m.z, 0.2, 0.55 * m.z) if _good else Color(0.6, 0.57, 0.55, 0.45 * m.z)
		draw_circle(p, 0.6 + 1.0 * m.z, col)
