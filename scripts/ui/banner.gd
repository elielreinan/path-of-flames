class_name Banner
extends Control
## Telas de informação grandes: capítulo novo, chefe apareceu e chefe derrotado.
## Faixas pretas de cinema, ornamentos e texto em camadas. Tocar na tela pula.

signal finished

enum Kind { CHAPTER, BOSS_INTRO, BOSS_DEFEATED, DEFEAT, QUEST_DONE, QUEST_FAILED, REWARD }

const GOLD := Color(1.0, 0.8, 0.3)
const EMBER := Color(1.0, 0.45, 0.15)
const VICTORY := Color(0.55, 0.95, 0.45)
const FAILURE := Color(0.85, 0.35, 0.3)
const CHAPTERS := 7

var kind := Kind.CHAPTER
var kicker := ""      # linha pequena acima ("CAPÍTULO 3", "CHEFE DERROTADO")
var headline := ""    # nome grande
var details: Array = []  # linhas pequenas embaixo
var chapter := 0      # para acender as chamas do progresso
var hold := 2.6

var _bars := 0.0       # 0..1 faixas de cinema
var _glow := 0.0       # brilho dos raios / ornamentos
var _flash := 0.0
var _time := 0.0
var _labels: Array[Label] = []
var _tween: Tween
var _done := false
var _motes: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var accent := _accent()
	var mid := _mid()
	_labels.append(_label(kicker, 10, accent, mid - 36.0, 4))
	_labels.append(_label(headline, 26 if kind == Kind.CHAPTER else 22, Color(1, 0.96, 0.88), mid - 24.0, 6))
	var dy := mid + 27.0
	for line in details:
		_labels.append(_label(line, 9, Color(0.9, 0.84, 0.74), dy, 3))
		dy += 13
	_flash = 1.0 if kind == Kind.BOSS_DEFEATED else 0.35 if kind == Kind.QUEST_DONE else 0.0
	# Brilhos subindo (vitória) ou cinzas caindo (falha).
	if kind in [Kind.QUEST_DONE, Kind.REWARD, Kind.QUEST_FAILED, Kind.BOSS_DEFEATED]:
		for i in 26:
			_motes.append(Vector3(randf(), randf(), randf_range(0.5, 1.0)))
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "_bars", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "_flash", 0.0, 0.5)
	_tween.tween_property(self, "_glow", 1.0, 0.4)
	for i in _labels.size():
		var l := _labels[i]
		_tween.parallel().tween_property(l, "modulate:a", 1.0, 0.5).set_delay(0.15 * i)
		_tween.parallel().tween_property(l, "position:x", l.position.x + 12.0, 0.6).from(l.position.x).set_delay(0.15 * i) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold)
	_tween.tween_callback(_close)


func _accent() -> Color:
	match kind:
		Kind.BOSS_INTRO: return EMBER
		Kind.DEFEAT: return Color(0.9, 0.25, 0.2)
		Kind.QUEST_DONE: return VICTORY
		Kind.QUEST_FAILED: return FAILURE
	return GOLD


func _mid() -> float:
	match kind:
		Kind.BOSS_DEFEATED: return 120.0
		Kind.QUEST_DONE, Kind.QUEST_FAILED, Kind.REWARD: return 140.0
	return 128.0


func _label(text: String, size: int, color: Color, y: float, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(-12, y)
	# Largura real da tela: em celulares 20:9 a visão fica mais larga que 480.
	l.size = Vector2(get_viewport_rect().size.x, size + 8)
	l.modulate.a = 0.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and _time > 0.6:
		accept_event()
		_close()


func _close() -> void:
	if _done:
		return
	_done = true
	if _tween:
		_tween.kill()
	# Pulou no meio da animação: alinha tudo no centro antes de sumir.
	for l in _labels:
		l.position.x = 0.0
		l.modulate.a = 1.0
	var out := create_tween()
	out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	out.tween_property(self, "modulate:a", 0.0, 0.4)
	await out.finished
	finished.emit()
	queue_free()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var mid := _mid()
	# Escurece o jogo e põe faixas de cinema.
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.72 * _bars))
	var accent := _accent()
	var c := Vector2(w / 2.0, mid)
	if kind == Kind.BOSS_DEFEATED:
		# Raios dourados girando atrás do nome.
		for i in 16:
			var ang := TAU * i / 16.0 + _time * 0.4
			var p1 := c + Vector2.from_angle(ang - 0.06) * 160.0
			var p2 := c + Vector2.from_angle(ang + 0.06) * 160.0
			draw_colored_polygon(PackedVector2Array([c, p1, p2]), Color(GOLD, 0.10 * _glow))
	var bar_h := 34.0 * _bars
	# Faixa central com degradê.
	var band := Rect2(0, mid - 50, w, 100 + 14 * details.size())
	for i in 12:
		var a := (1.0 - absf(i - 5.5) / 6.0) * 0.55 * _bars
		draw_rect(Rect2(0, band.position.y + i * band.size.y / 12.0, w, band.size.y / 12.0 + 1), Color(0.08, 0.04, 0.02, a))
	draw_rect(Rect2(0, 0, w, bar_h), Color.BLACK)
	draw_rect(Rect2(0, h - bar_h, w, bar_h), Color.BLACK)
	if _flash > 0.0:
		draw_rect(Rect2(0, 0, w, h), Color(1, 1, 0.9, _flash * 0.8))
	# Partículas: sobem na vitória, caem na falha.
	for m in _motes:
		var falling := kind == Kind.QUEST_FAILED
		var y := fmod(m.y + _time * 0.12 * m.z * (1.0 if falling else -1.0) + 2.0, 1.0)
		var p := Vector2(m.x * w + sin(_time * 2.0 + m.x * 20.0) * 6.0, y * h)
		var col := Color(0.6, 0.55, 0.5, 0.5 * _bars) if falling else Color(accent.lerp(Color.WHITE, 0.4), 0.7 * _bars * m.z)
		draw_circle(p, 1.2 * m.z + 0.3, col)
	if _glow < 0.05:
		return
	# Linhas ornamentais com losango no meio, acima e abaixo do texto.
	var span := 150.0 * _glow
	for y in [mid - 40.0, mid + 22.0]:
		draw_line(Vector2(c.x - span, y), Vector2(c.x - 8, y), Color(accent, 0.9), 1.0)
		draw_line(Vector2(c.x + 8, y), Vector2(c.x + span, y), Color(accent, 0.9), 1.0)
		var d := 4.0 * _glow
		draw_colored_polygon(PackedVector2Array([Vector2(c.x, y - d), Vector2(c.x + d, y), Vector2(c.x, y + d), Vector2(c.x - d, y)]), accent)
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(c.x + side * (span + 4.0), y), 1.5 * _glow, accent)
	# Progresso dos capítulos: sete chamas, acesas até o atual.
	if kind == Kind.CHAPTER and chapter > 0:
		var start := c.x - (CHAPTERS - 1) * 9.0
		for i in CHAPTERS:
			var p := Vector2(start + i * 18.0, mid + 36.0)
			var lit := i < chapter
			var flicker := 1.0 + 0.15 * sin(_time * 9.0 + i) if lit else 1.0
			var col := Color(1, 0.55 + 0.25 * float(i == chapter - 1), 0.15, _glow) if lit else Color(0.4, 0.35, 0.3, 0.6 * _glow)
			_flame(p, 5.0 * flicker, col)
	if kind in [Kind.QUEST_DONE, Kind.QUEST_FAILED, Kind.REWARD]:
		_emblem(Vector2(c.x, mid - 64.0), accent)
	if kind == Kind.BOSS_INTRO:
		# Bordas vermelhas pulsando: perigo.
		var pulse := 0.25 + 0.2 * sin(_time * 6.0)
		draw_rect(Rect2(0, bar_h, w, 3), Color(EMBER, pulse * _bars))
		draw_rect(Rect2(0, h - bar_h - 3, w, 3), Color(EMBER, pulse * _bars))


## Selo acima do texto: visto (concluída), selo partido com X (falhou) ou estrela (recompensa).
func _emblem(p: Vector2, accent: Color) -> void:
	var r := 13.0 * _glow
	if r < 1.0:
		return
	var spin := _time * 0.8
	if kind != Kind.QUEST_FAILED:
		for i in 12:
			var a := TAU * i / 12.0 + spin
			draw_line(p + Vector2.from_angle(a) * (r + 3), p + Vector2.from_angle(a) * (r + 7), Color(accent, 0.6 * _glow), 1.5)
	draw_circle(p, r + 1.5, Color(0, 0, 0, 0.7))
	draw_circle(p, r, Color(accent.darkened(0.45), _glow))
	draw_arc(p, r, 0, TAU, 32, accent, 1.5)
	var ink := Color(1, 0.97, 0.88, _glow)
	match kind:
		Kind.QUEST_DONE:
			draw_polyline(PackedVector2Array([p + Vector2(-6, 0), p + Vector2(-2, 5), p + Vector2(7, -5)]), ink, 3.0)
		Kind.QUEST_FAILED:
			draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), ink, 3.0)
			draw_line(p + Vector2(5, -5), p + Vector2(-5, 5), ink, 3.0)
			# Rachadura do selo.
			draw_polyline(PackedVector2Array([p + Vector2(0, -r), p + Vector2(2, -r * 0.5), p + Vector2(-1, -r * 0.2)]), Color(0, 0, 0, 0.8), 1.5)
		Kind.REWARD:
			var pts := PackedVector2Array()
			for i in 10:
				var rad := 8.0 if i % 2 == 0 else 3.5
				pts.append(p + Vector2.from_angle(-PI / 2 + TAU * i / 10.0) * rad)
			draw_colored_polygon(pts, ink)


func _flame(p: Vector2, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 1.8), p + Vector2(s * 0.8, -s * 0.2), p + Vector2(s * 0.5, s * 0.7),
		p + Vector2(-s * 0.5, s * 0.7), p + Vector2(-s * 0.8, -s * 0.2)]), col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s * 0.8), p + Vector2(s * 0.35, s * 0.3), p + Vector2(-s * 0.35, s * 0.3)]),
		Color(1, 0.95, 0.6, col.a))
