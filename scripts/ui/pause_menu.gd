class_name PauseMenu
extends Control
## Menu de pausa enxuto: Continuar em destaque, atalhos com ícone e o resto numa linha.
## `choice` diz o que o jogador escolheu ("" = continuar); o World abre a tela correspondente.

signal closed

var choice := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Pausado", Vector2(250, 150))
	add_child(w.root)
	w.close.visible = false
	var where := UiKit.label("%s  ·  Nv %d" % [Data.map(GameState.map_id).get("nome", ""), GameState.level], 9, UiKit.MUTED)
	w.box.add_child(where)
	var cont := UiKit.button("Continuar", 13)
	cont.custom_minimum_size.y = 30
	cont.pressed.connect(func(): _pick(""))
	w.box.add_child(cont)
	var icons := HBoxContainer.new()
	icons.add_theme_constant_override("separation", 6)
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	w.box.add_child(icons)
	for entry in [["bolsa", "Bolsa"], ["missoes", "Missões"], ["mapa", "Mapa"]]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		var b := IconButton.make(entry[0], 34)
		var id: String = entry[0]
		b.pressed.connect(func(): _pick(id))
		col.add_child(b)
		var l := UiKit.label(entry[1], 8, UiKit.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		col.add_child(l)
		icons.add_child(col)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	w.box.add_child(bottom)
	for entry in [["config", "Configurações"], ["titulo", "Salvar e sair"]]:
		var b := UiKit.button(entry[1], 10)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id: String = entry[0]
		b.pressed.connect(func(): _pick(id))
		bottom.add_child(b)


func _pick(id: String) -> void:
	choice = id
	closed.emit()
