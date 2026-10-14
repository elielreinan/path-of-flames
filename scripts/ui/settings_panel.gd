class_name SettingsPanel
extends Control
## Configurações: controles, texto, mini mapa e volume. Tudo é salvo na hora.

signal closed

var _rows: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Configurações", Vector2(400, 240))
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(384, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	w.box.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 5)
	scroll.add_child(_rows)
	_build()
	Settings.changed.connect(_build)


func _build() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_choice_row("Tamanho do joystick", "tamanho_joystick")
	_choice_row("Joystick", "joystick_modo")
	_choice_row("Tamanho dos botões", "tamanho_botoes")
	_choice_row("Opacidade dos controles", "opacidade")
	_choice_row("Velocidade do texto", "velocidade_texto")
	_choice_row("Mini mapa", "mini_mapa")
	_choice_row("Tremer a tela", "tremer_tela")
	_volume_row("Volume da música", "volume_musica")
	_volume_row("Volume dos efeitos", "volume_efeitos")


func _label(text: String) -> Label:
	var l := UiKit.label(text, 10)
	l.custom_minimum_size.x = 130
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _choice_row(text: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(text))
	var options: Array = Settings.OPTIONS[key]
	for i in options.size():
		var b := UiKit.button(options[i], 9)
		if i == Settings.get_value(key):
			var on := UiKit.selected_style()
			b.add_theme_stylebox_override("normal", on)
			b.add_theme_stylebox_override("hover", on)
		var index := i
		b.pressed.connect(func(): Settings.set_value.call_deferred(key, index))
		row.add_child(b)
	_rows.add_child(row)


func _volume_row(text: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_child(_label(text))
	var minus := UiKit.button("-", 10)
	minus.custom_minimum_size.x = 22
	minus.pressed.connect(func(): Settings.set_value.call_deferred(key, maxi(Settings.get_value(key) - 1, 0)))
	row.add_child(minus)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(120, 8)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = 10
	bar.value = Settings.get_value(key)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiKit.ACCENT
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	row.add_child(bar)
	var plus := UiKit.button("+", 10)
	plus.custom_minimum_size.x = 22
	plus.pressed.connect(func(): Settings.set_value.call_deferred(key, mini(Settings.get_value(key) + 1, 10)))
	row.add_child(plus)
	row.add_child(UiKit.label(str(Settings.get_value(key)), 10, UiKit.MUTED))
	_rows.add_child(row)
