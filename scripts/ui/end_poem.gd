extends Control
## Poema do fim: duas vozes conversam sobre o jogador enquanto o texto sobe devagar.
## Voz dourada e voz turquesa alternadas. Segurar o dedo na tela acelera; "Pular" encerra.

signal finished

const VOICE_A := Color(1.0, 0.82, 0.4)
const VOICE_B := Color(0.45, 0.9, 0.85)
const SPEED := 15.0
const FAST := 6.0

## Cada linha é dita por uma das vozes (0 = dourada, 1 = turquesa), sempre alternando.
const POEM := [
	"Eu vejo o jogador de quem você falou.",
	"Ifrit?",
	"Não. Ifrit era o nome que ele vestiu. O jogador é outro.",
	"Ele segura uma pequena tela brilhante nas mãos. A luz dela ilumina o rosto dele no escuro.",
	"Através dessa luz ele andou pela Areia Rubra. Sentiu o calor das dunas sem sair do lugar.",
	"Ele acendeu sete chamas.",
	"Areia Rubra, Miraj, Porto Coral, o Vale, Qadim, a Cidadela... e o Trono.",
	"Sete chamas. Mas ele carregava uma oitava, sem saber.",
	"Qual?",
	"A que ele trouxe de fora. A que já estava acesa antes de o jogo começar.",
	"Ele enfrentou escorpiões, piratas e golens de vidro. Enfrentou um rei feito de cinzas.",
	"Coisas que não eram reais.",
	"Mas as escolhas foram reais.",
	"Sim. Cada vez que podia mentir e disse a verdade. Cada vez que podia dizer a verdade e mentiu.",
	"Nós contamos todas. Demos a isso o nome de honra.",
	"A honra não é um número. Mas era o nosso jeito de dizer a ele: nós vimos.",
	"Ele achava que estava sozinho quando escolhia.",
	"Ninguém está sozinho quando escolhe. As escolhas ficam. Elas ecoam.",
	"Às vezes ele parava. Olhava o sol se pondo sobre um deserto de pixels e não fazia nada.",
	"Eu gostava desses momentos.",
	"Eu também. Era quando ele estava mais perto de nós.",
	"Ele sabe que isto é um sonho?",
	"Às vezes. Quando a tela se apaga e ele vê o próprio reflexo no vidro escuro.",
	"E o que ele vê?",
	"Um rosto cansado. Um rosto que acabou de salvar um reino.",
	"Os dois são o mesmo rosto.",
	"Então diga isso a ele.",
	"Jogador. Você foi Ifrit. Foi filho, amigo, guardião.",
	"Mas antes de tudo isso você já era alguém.",
	"Alguém que escolhe. Alguém que levanta quando cai. Alguém que acende o que estava apagado.",
	"As chamas que você reacendeu eram feitas de luz e de números.",
	"As que ardem dentro de você são feitas de outra coisa.",
	"Cuide delas.",
	"Lá fora existe um mundo sem barra de vida. Sem diário de missões. Sem mapa.",
	"Ele assusta, às vezes. É maior que Zahra inteira.",
	"Mas é lá que as escolhas pesam de verdade. E lá a honra não precisa de número.",
	"Ele vai se lembrar de nós?",
	"Talvez não. Talvez lembre só de uma música, de uma cor de areia, de um nome.",
	"Já basta.",
	"Jogador, o sonho está terminando. Mas quem sonha continua.",
	"Você leu as nossas palavras. Agora leia as suas.",
	"Conheça a ti mesmo.",
	"Você é a chama que nunca se apagou.",
	"Agora acorde.",
	"E quando quiser voltar, o deserto ainda estará aqui. Esperando por você.",
]

var _content: VBoxContainer
var _labels: Array[Label] = []
var _scroll := 0.0
var _holding := false
var _time := 0.0
var _end_time := -1.0
var _done := false
var _stars: Array = []
var _skip: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 70:
		_stars.append(Vector3(randf(), randf(), randf()))
	var vs := get_viewport_rect().size
	var width := minf(vs.x - 48.0, 420.0)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 9)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.position = Vector2((vs.x - width) / 2.0, vs.y)
	_content.size = Vector2(width, 0)
	add_child(_content)
	for i in POEM.size():
		var l := Label.new()
		l.text = POEM[i]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(width, 0)
		var color: Color = VOICE_A if i % 2 == 0 else VOICE_B
		var size := 10
		if POEM[i] == "Conheça a ti mesmo.":
			size = 13
			color = Color(1, 0.97, 0.9)
		l.add_theme_font_size_override("font_size", size)
		l.add_theme_color_override("font_color", color)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", 3)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(l)
		_labels.append(l)
	_skip = UiKit.button("Pular", 8)
	_skip.process_mode = Node.PROCESS_MODE_ALWAYS
	_skip.pressed.connect(_close)
	add_child(_skip)


func _process(delta: float) -> void:
	_time += delta
	var vs := get_viewport_rect().size
	_skip.reset_size()
	_skip.position = Vector2(vs.x - _skip.size.x - 10.0, 8.0)
	if _end_time < 0.0:
		_scroll += delta * SPEED * (FAST if _holding else 1.0)
	_content.position.y = vs.y + 6.0 - _scroll
	# Some aos poucos perto das bordas de cima e de baixo.
	var fade := 34.0
	for l in _labels:
		var cy := _content.position.y + l.position.y + l.size.y / 2.0
		l.modulate.a = clampf(minf(cy / fade - 0.4, (vs.y - cy) / fade), 0.0, 1.0)
	if _end_time < 0.0 and not _labels.is_empty():
		var last := _labels[-1]
		if _content.position.y + last.position.y + last.size.y / 2.0 <= vs.y * 0.5:
			_end_time = _time
	elif _end_time >= 0.0 and _time - _end_time > 3.5:
		_close()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_holding = event.pressed
		accept_event()
		# Toque depois de terminar: fecha logo.
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
	out.tween_property(_content, "modulate:a", 0.0, 1.2)
	out.parallel().tween_property(_skip, "modulate:a", 0.0, 0.3)
	await out.finished
	finished.emit()
	queue_free()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.05))
	# Céu do deserto à noite: estrelas piscando devagar.
	for s in _stars:
		var a := 0.25 + 0.5 * (0.5 + 0.5 * sin(_time * (0.6 + s.z) + s.x * 40.0))
		draw_rect(Rect2(floorf(s.x * w), floorf(s.y * h), 1, 1), Color(0.9, 0.9, 1.0, a * (0.4 + 0.6 * s.z)))
	# Uma brasa pequena pulsando no rodapé, como uma tela acesa no escuro.
	var p := Vector2(w / 2.0, h - 14.0)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	draw_circle(p, 5.0 + pulse * 2.0, Color(1.0, 0.6, 0.2, 0.12))
	draw_circle(p, 2.0, Color(1.0, 0.8, 0.4, 0.6 + 0.3 * pulse))
