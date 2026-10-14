class_name DialogBox
extends Control
## Caixa de diálogo: retrato de quem fala, nome numa aba, texto aparecendo aos poucos,
## seta piscando quando dá para avançar, e escolhas em lista.

signal _advance
signal _chosen(index: int)

## Retratos por nome de quem fala, montados na primeira vez que são usados.
static var _portraits: Dictionary = {}

var _panel: PanelContainer
var _portrait_frame: PanelContainer
var _portrait: TextureRect
var _name_tab: PanelContainer
var _name: Label
var _text: Label
var _choices: VBoxContainer
var _choices_panel: PanelContainer
var _portrait_column: HBoxContainer
var _arrow: Control
var _typing := false
var _blip := -1
var _waiting := false
var _time := 0.0


## Estilo Stardew Valley: moldura de madeira, papel claro com letra escura,
## retrato grande à esquerda com plaquinha do nome embaixo.
const WOOD := Color(0.45, 0.24, 0.1)
const WOOD_LIGHT := Color(0.85, 0.55, 0.25)
const PAPER := Color(0.99, 0.88, 0.64)
const INK := Color(0.27, 0.14, 0.06)
const INK_SOFT := Color(0.45, 0.32, 0.2)


static func wood_style(bg := PAPER, border := 4, margin := 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = WOOD
	style.set_border_width_all(border)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(margin)
	# Brilho interno da madeira.
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 8
	_panel.offset_right = -8
	_panel.offset_top = -98
	_panel.offset_bottom = -6
	# Moldura dupla: madeira escura por fora, filete claro por dentro.
	var outer := wood_style(WOOD_LIGHT, 3, 2)
	_panel.add_theme_stylebox_override("panel", outer)
	add_child(_panel)
	var paper := PanelContainer.new()
	paper.add_theme_stylebox_override("panel", wood_style(PAPER, 2, 7))
	_panel.add_child(paper)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	paper.add_child(row)

	_text = UiKit.label("", 11, INK)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_constant_override("line_spacing", 2)
	row.add_child(_text)

	# Coluna do retrato: separador de madeira, quadro e plaquinha com o nome.
	_portrait_column = HBoxContainer.new()
	_portrait_column.add_theme_constant_override("separation", 6)
	row.add_child(_portrait_column)
	# Retrato à esquerda do texto.
	row.move_child(_portrait_column, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_portrait_column.add_child(column)
	var divider := ColorRect.new()
	divider.color = WOOD_LIGHT
	divider.custom_minimum_size = Vector2(2, 0)
	_portrait_column.add_child(divider)
	_portrait_frame = PanelContainer.new()
	var frame_style := wood_style(Color(0.96, 0.78, 0.5), 2, 2)
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	_portrait_frame.custom_minimum_size = Vector2(60, 56)
	column.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_frame.add_child(_portrait)
	_name_tab = PanelContainer.new()
	var tab_style := wood_style(Color(0.96, 0.78, 0.5), 2, 1)
	tab_style.content_margin_left = 4
	tab_style.content_margin_right = 4
	_name_tab.add_theme_stylebox_override("panel", tab_style)
	column.add_child(_name_tab)
	_name = UiKit.label("", 8, INK)
	_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name.custom_minimum_size.x = 52
	_name.clip_text = true
	_name_tab.add_child(_name)

	_arrow = Control.new()
	_arrow.anchor_left = 1.0
	_arrow.anchor_right = 1.0
	_arrow.anchor_top = 1.0
	_arrow.anchor_bottom = 1.0
	_arrow.offset_left = -36
	_arrow.offset_top = -24
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_arrow)
	add_child(_arrow)

	_choices_panel = PanelContainer.new()
	_choices_panel.add_theme_stylebox_override("panel", wood_style(PAPER, 3, 5))
	_choices_panel.anchor_left = 1.0
	_choices_panel.anchor_right = 1.0
	_choices_panel.anchor_top = 1.0
	_choices_panel.anchor_bottom = 1.0
	_choices_panel.offset_left = -290
	_choices_panel.offset_right = -10
	_choices_panel.offset_bottom = -102
	_choices_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_choices_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_choices_panel.visible = false
	add_child(_choices_panel)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 3)
	_choices_panel.add_child(_choices)


## Opção de resposta no papel: muda de cor ao tocar, como no Stardew.
static func choice_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 10)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(3)
	normal.content_margin_left = 6
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.96, 0.7, 0.4)
	hover.border_color = WOOD
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(2)
	hover.set_content_margin_all(3)
	hover.content_margin_left = 6
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.custom_minimum_size.y = 20
	# Escolhas longas quebram a linha em vez de sair da tela.
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = 266
	return b


func _process(delta: float) -> void:
	_time += delta
	if _typing and visible:
		var shown := int(_text.visible_ratio * _text.text.length()) / 3
		if shown != _blip:
			_blip = shown
			Som.sfx("letra", -14.0, 0.15, 0.03)
	if visible:
		_arrow.queue_redraw()


func _draw_arrow() -> void:
	if not _waiting or _typing or _choices_panel.visible:
		return
	var bob := sin(_time * 6.0) * 2.0
	var c := Vector2(10, 8 + bob)
	_arrow.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -4), c + Vector2(6, -4), c + Vector2(0, 4)]), WOOD)
	_arrow.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -3), c + Vector2(3, -3), c + Vector2(0, 1)]), WOOD_LIGHT)


func _gui_input(event: InputEvent) -> void:
	# No celular o toque também chega como clique de mouse emulado; tratar só o clique evita avançar duas vezes.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tap()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event.is_action_pressed("attack")):
		_on_tap()
		get_viewport().set_input_as_handled()


func _on_tap() -> void:
	if _typing:
		_text.visible_ratio = 1.0
		_typing = false
	elif _waiting:
		_advance.emit()


## Retrato de quem fala (ou null para narração).
static func portrait_for(speaker: String) -> Texture2D:
	if speaker == "":
		return null
	if _portraits.is_empty():
		_portraits["Ifrit"] = IfritRig.portrait()
		for id in Data.npcs:
			var npc: Dictionary = Data.npcs[id]
			if npc.has("nome") and not _portraits.has(npc.nome):
				var face: Texture2D = null if npc.has("sprite") else SkinSprite.portrait(id)
				if face:
					_portraits[npc.nome] = face
				else:
					_portraits[npc.nome] = load(npc.sprite) if npc.has("sprite") else CharacterSprite.make(npc.get("aparencia", {}))
		for id in Data.enemies:
			var enemy: Dictionary = Data.enemies[id]
			if enemy.has("nome") and not _portraits.has(enemy.nome):
				var enemy_face: Texture2D = SkinSprite.portrait(id) if enemy.has("aparencia") else null
				if enemy_face:
					_portraits[enemy.nome] = enemy_face
				else:
					if CreatureSprite.has(enemy.get("criatura", "")):
						_portraits[enemy.nome] = CreatureSprite.portrait(enemy.criatura)
					else:
						_portraits[enemy.nome] = CharacterSprite.make(enemy.aparencia) if enemy.has("aparencia") else load(enemy.sprite)
	return _portraits.get(speaker)


func _show_line(speaker: String, text: String) -> void:
	_name.text = speaker.split(",")[0]
	# Nomes compridos ("Rainha Escorpião") usam letra menor em vez de cortar.
	var size := 8 if _name.text.length() <= 10 else (7 if _name.text.length() <= 13 else 6)
	_name.add_theme_font_size_override("font_size", size)
	if _name.text.length() > 18 and " " in _name.text:
		# Muito comprido: duas linhas, quebrando no espaço mais perto do meio.
		var mid := _name.text.length() / 2
		var cut := _name.text.rfind(" ", mid)
		var after := _name.text.find(" ", mid)
		if cut < 0 or (after >= 0 and after - mid < mid - cut):
			cut = after
		_name.text = _name.text.substr(0, cut) + "\n" + _name.text.substr(cut + 1)
	var tex := portrait_for(speaker)
	_portrait.texture = tex
	# Narração (sem quem fala) usa a caixa inteira, em itálico de tom mais suave.
	_portrait_column.visible = speaker != ""
	_portrait_frame.visible = tex != null
	_text.text = text
	_text.add_theme_color_override("font_color", INK if speaker != "" else INK_SOFT)
	_arrow.offset_left = -36


## Mostra as linhas do diálogo. Devolve a escolha feita (ou {} se não houver escolhas).
func play(dialog: Dictionary) -> Dictionary:
	visible = true
	for line in dialog.get("linhas", []):
		_show_line(line.get("s", ""), line.get("t", ""))
		var speed := Settings.text_speed()
		var tween: Tween
		if speed <= 0.0:
			_text.visible_ratio = 1.0
			_typing = false
		else:
			_text.visible_ratio = 0.0
			_typing = true
			tween = create_tween()
			tween.tween_property(_text, "visible_ratio", 1.0, _text.text.length() / speed)
			tween.finished.connect(func(): _typing = false)
		_waiting = true
		await _advance
		_waiting = false
		if tween:
			tween.kill()
	var choice := {}
	var options: Array = dialog.get("escolhas", [])
	if not options.is_empty():
		for i in options.size():
			var b := choice_button("› " + str(options[i].t))
			b.pressed.connect(func(): _chosen.emit(i))
			_choices.add_child(b)
		_choices_panel.visible = true
		var index: int = await _chosen
		choice = options[index]
		_choices_panel.visible = false
		for child in _choices.get_children():
			child.queue_free()
	visible = false
	return choice
