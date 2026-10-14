class_name TitleScreen
extends Control
## Tela inicial: novo jogo ou continuar.

signal chosen(new_game: bool)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Som.music("titulo")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -150
	box.offset_right = 150
	box.offset_top = -70
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := UiKit.label("PATH OF FLAMES", 24, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := UiKit.label("As Sete Chamas de Zahra", 10, UiKit.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var start := UiKit.button("Novo jogo", 12)
	start.pressed.connect(func(): chosen.emit(true))
	box.add_child(start)
	var cont := UiKit.button("Continuar", 12)
	cont.disabled = not GameState.has_save()
	cont.pressed.connect(func(): chosen.emit(false))
	box.add_child(cont)
