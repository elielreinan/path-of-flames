class_name Hud
extends CanvasLayer
## Interface do jogo: vida, nível, moeda local, missão atual, chefe, avisos e controles de toque.

signal open_inventory
signal open_quests
signal open_pause
signal open_map

var joystick: TouchJoystick
var currency := "brasas"

var minimap: MiniMap
var _controls: Control
var _fire_button: ActionButton
var _cooldown_buttons := {}
var _player: Player
var _map_tween: Tween
var _status_row: HBoxContainer
var _hp_bar: ProgressBar
var _hp_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _money_label: Label
var _tracker: Label
var _toasts: VBoxContainer
var _map_name: Label
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_name: Label
var _title: Label
var _subtitle: Label
var _message: Label

var _special_button: ActionButton
var _mount_button: ActionButton
## Telas grandes abertas agora (os botões só voltam quando todas fecharem).
var _banners := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Status no canto superior esquerdo.
	var status := VBoxContainer.new()
	status.position = Vector2(6, 4)
	status.add_theme_constant_override("separation", 1)
	root.add_child(status)
	var row := HBoxContainer.new()
	status.add_child(row)
	_level_label = _outlined("Nv 1", 9, UiKit.ACCENT)
	row.add_child(_level_label)
	_hp_bar = _bar(Color(0.85, 0.2, 0.2), Vector2(70, 7))
	row.add_child(_hp_bar)
	_hp_label = _outlined("", 8)
	row.add_child(_hp_label)
	_xp_bar = _bar(Color(0.3, 0.6, 1.0), Vector2(98, 3))
	status.add_child(_xp_bar)
	_money_label = _outlined("", 9, Color(1, 0.85, 0.3))
	status.add_child(_money_label)
	_status_row = HBoxContainer.new()
	_status_row.add_theme_constant_override("separation", 6)
	status.add_child(_status_row)

	# Canto superior direito: pausa, bolsa e missões ao lado do mini mapa; missão atual embaixo.
	var right := VBoxContainer.new()
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -190
	right.offset_right = -6
	right.offset_top = 4
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(right)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_child(top)
	var icons := VBoxContainer.new()
	icons.add_theme_constant_override("separation", 3)
	top.add_child(icons)
	for entry in [["pausa", open_pause], ["bolsa", open_inventory], ["missoes", open_quests]]:
		var b := IconButton.make(entry[0], 20)
		var sig: Signal = entry[1]
		b.pressed.connect(func(): sig.emit())
		icons.add_child(b)
	minimap = MiniMap.new()
	minimap.custom_minimum_size = Vector2(104, 66)
	minimap.pressed.connect(func(): open_map.emit())
	top.add_child(minimap)
	_tracker = _outlined("", 8)
	_tracker.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tracker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_tracker)
	Settings.changed.connect(func(): minimap.visible = Settings.get_value("mini_mapa") == 1)
	minimap.visible = Settings.get_value("mini_mapa") == 1

	_toasts = VBoxContainer.new()
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toasts.offset_top = 40
	_toasts.offset_left = -120
	_toasts.offset_right = 120
	# Textos longos crescem para os dois lados e continuam centralizados.
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toasts)

	_map_name = _outlined("", 14, UiKit.ACCENT)
	_map_name.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_map_name.offset_top = 22
	_map_name.offset_left = -150
	_map_name.offset_right = 150
	_map_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_map_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_map_name.modulate.a = 0.0
	root.add_child(_map_name)

	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.offset_left = -110
	_boss_box.offset_right = 110
	_boss_box.offset_top = -100
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_name = _outlined("", 10, Color(1, 0.5, 0.4))
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	_boss_bar = _bar(Color(0.8, 0.15, 0.3), Vector2(220, 8))
	_boss_box.add_child(_boss_bar)

	# Controles de toque.
	_controls = Control.new()
	_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_controls)
	joystick = TouchJoystick.new()
	_controls.add_child(joystick)
	var buttons := Control.new()
	buttons.anchor_left = 1.0
	buttons.anchor_top = 1.0
	buttons.anchor_right = 1.0
	buttons.anchor_bottom = 1.0
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.add_child(buttons)
	# GOLPE grande no canto; FOGO e FALAR em arco em volta, longe o bastante para não tocar dois de uma vez.
	_add_action(buttons, "attack", "GOLPE", "espada", Color(1, 0.6, 0.1), 28.0, Vector2(-46, -50))
	_fire_button = _add_action(buttons, "fireball", "FOGO", "fogo", Color(0.9, 0.25, 0.1), 21.0, Vector2(-110, -34))
	_add_action(buttons, "interact", "FALAR", "falar", Color(0.3, 0.6, 0.9), 21.0, Vector2(-38, -116))
	_special_button = _add_action(buttons, "especial", "ESPECIAL", "especial", Color(0.95, 0.35, 0.15), 18.0, Vector2(-100, -96))
	_mount_button = _add_action(buttons, "montar", "MONTAR", "montar", Color(0.6, 0.45, 0.25), 15.0, Vector2(-160, -78))
	var quick := _add_action(buttons, "item_rapido", "", "item", Color(0.25, 0.6, 0.35), 17.0, Vector2(-158, -28))
	quick.item_source = func(): return GameState.quick_item
	quick.cooldown_source = func(): return GameState.item_cooldown / GameState.ITEM_COOLDOWN
	_cooldown_buttons = {"attack": _attack_button_ref(buttons), "fireball": _fire_button, "especial": _special_button}

	# Título de capítulo e mensagens grandes.
	_title = _outlined("", 20, UiKit.ACCENT)
	_title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_title.offset_left = -220
	_title.offset_right = 220
	_title.offset_top = -30
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title.modulate.a = 0.0
	root.add_child(_title)
	_subtitle = _outlined("", 11)
	_subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_subtitle.offset_left = -220
	_subtitle.offset_right = 220
	_subtitle.offset_top = 0
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_subtitle.modulate.a = 0.0
	root.add_child(_subtitle)
	_message = _outlined("", 16)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_message.offset_left = -200
	_message.offset_right = 200
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_message)

	GameState.changed.connect(refresh)
	GameState.toast.connect(toast)
	refresh()


func _outlined(text: String, size: int, color := UiKit.TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar(color: Color, size: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = size
	bar.show_percentage = false
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _add_action(parent: Control, action: String, text: String, icon: String, color: Color, radius: float, center: Vector2) -> ActionButton:
	var button := ActionButton.new()
	button.action = action
	button.label = text
	button.icon = icon
	button.color = color
	button.base_radius = radius
	button.anchor_offset = center
	parent.add_child(button)
	return button


func _attack_button_ref(parent: Control) -> ActionButton:
	for child in parent.get_children():
		if child is ActionButton and child.action == "attack":
			return child
	return null


## O World chama ao criar o Ifrit: os botões mostram a recarga de cada habilidade.
func bind_player(player: Player) -> void:
	_player = player
	for action in _cooldown_buttons:
		var button: ActionButton = _cooldown_buttons[action]
		if button:
			button.cooldown_source = func(): return player.cooldown_fraction(action) if is_instance_valid(player) else 0.0


func _process(_delta: float) -> void:
	# Efeitos de status ativos no Ifrit, com o tempo restante.
	var active: Dictionary = _player.status.active if is_instance_valid(_player) else {}
	while _status_row.get_child_count() < active.size():
		_status_row.add_child(_outlined("", 8))
	var i := 0
	for child in _status_row.get_children():
		if i < active.size():
			var effect: String = active.keys()[i]
			var info: Dictionary = StatusEffects.INFO[effect]
			child.text = "%s %ds" % [info.nome, ceili(active[effect].t)]
			child.add_theme_color_override("font_color", info.cor)
			child.visible = true
		else:
			child.visible = false
		i += 1


func refresh() -> void:
	_level_label.text = "Nv %d" % GameState.level
	_hp_bar.max_value = GameState.max_hp()
	_hp_bar.value = GameState.hp
	_hp_label.text = "%d/%d" % [GameState.hp, GameState.max_hp()]
	_xp_bar.max_value = GameState.xp_to_next()
	_xp_bar.value = GameState.xp
	_money_label.text = "%s: %d" % [Data.currency_name(currency), GameState.money(currency)]
	var quest := GameState.tracked_quest()
	_fire_button.enabled = GameState.has_flag("magia_fogo")
	_special_button.enabled = GameState.has_flag("golpe_especial")
	_special_button.ready_glow = GameState.fury >= GameState.FURY_MAX
	_mount_button.visible = not GameState.mounts.is_empty()
	_tracker.text = "" if quest == "" else "%s\n%s" % [Data.quests[quest].titulo, GameState.objective_text(quest)]


func set_controls_visible(value: bool) -> void:
	_controls.visible = value
	joystick.output = Vector2.ZERO


func toast(text: String) -> void:
	var l := _outlined(text, 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toasts.add_child(l)
	var tween := l.create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(l, "modulate:a", 0.0, 0.6)
	tween.tween_callback(l.queue_free)


func show_map_name(text: String) -> void:
	_map_name.text = text
	if _map_tween:
		_map_tween.kill()
	_map_tween = create_tween()
	var tween := _map_tween
	tween.tween_property(_map_name, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.8)
	tween.tween_property(_map_name, "modulate:a", 0.0, 0.6)


func show_title(title: String, subtitle: String) -> void:
	var chapter := 0
	if title.begins_with("Capítulo"):
		chapter = int(title.get_slice(" ", 1))
	elif title == "Epílogo":
		chapter = Banner.CHAPTERS
	var details := []
	if title == "FIM":
		details = ["%s  ·  %s" % [GameState.rank(), GameState.honor_title()], "Nível %d" % GameState.level]
	await show_banner(Banner.Kind.CHAPTER, title.to_upper(), subtitle, details, chapter)


## Tela de informação grande (capítulo, chefe). Espera terminar ou o jogador tocar.
func show_banner(kind: Banner.Kind, kicker: String, headline: String, details: Array = [], chapter := 0) -> void:
	# A tela grande fica sozinha: sem controles nem nome do mapa por cima.
	set_controls_visible(false)
	if _map_tween:
		_map_tween.kill()
	_map_name.modulate.a = 0.0
	Som.banner(kind)
	var banner := Banner.new()
	banner.kind = kind
	banner.kicker = kicker
	banner.headline = headline
	banner.details = details
	banner.chapter = chapter
	_banners += 1
	add_child(banner)
	await banner.finished
	_banners -= 1
	if _banners == 0 and is_instance_valid(_player) and _player.controllable:
		set_controls_visible(true)


func show_message(text: String) -> void:
	_message.text = text


func show_boss(boss_name: String, hp: int, max_hp: int) -> void:
	_boss_box.visible = true
	_boss_name.text = boss_name
	update_boss(hp, max_hp)


func update_boss(hp: int, max_hp: int) -> void:
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	if hp <= 0:
		_boss_box.visible = false


func hide_boss() -> void:
	_boss_box.visible = false
