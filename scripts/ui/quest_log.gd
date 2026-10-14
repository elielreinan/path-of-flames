class_name QuestLog
extends Control
## Diário de missões: principais e secundárias, com objetivos e progresso.

signal closed

var _list: VBoxContainer
var _info: Label
var _show_done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Missões", Vector2(420, 230))
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())
	var toggle := UiKit.button("Ver concluídas")
	toggle.pressed.connect(func():
		_show_done = not _show_done
		toggle.text = "Ver em andamento" if _show_done else "Ver concluídas"
		_refresh())
	w.header.add_child(toggle)
	w.header.move_child(toggle, 1)
	var columns := HBoxContainer.new()
	w.box.add_child(columns)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(180, 180)
	columns.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_info = UiKit.label("", 9)
	_info.custom_minimum_size = Vector2(210, 0)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(_info)
	_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var first := ""
	for kind in ["principal", "secundaria"]:
		var header := UiKit.label("Principais" if kind == "principal" else "Secundárias", 9, UiKit.ACCENT)
		_list.add_child(header)
		var any := false
		for id in GameState.quests:
			var done: bool = GameState.quests[id].estado in ["concluida", "falhou"]
			if Data.quests[id].tipo != kind or done != _show_done:
				continue
			any = true
			if first == "":
				first = id
			var b := UiKit.button("%s (nv %d)" % [Data.quests[id].titulo, Data.quests[id].get("nivel", 1)])
			if GameState.quests[id].estado == "falhou":
				b.text = "%s (falhou)" % Data.quests[id].titulo
				b.add_theme_color_override("font_color", Color(0.85, 0.45, 0.4))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.pressed.connect(_select.bind(id))
			_list.add_child(b)
		if not any:
			_list.add_child(UiKit.label("Nenhuma.", 8, UiKit.MUTED))
	if first != "":
		_select(first)
	else:
		_info.text = ""


func _select(id: String) -> void:
	var quest: Dictionary = Data.quests[id]
	var lines := ["%s" % quest.titulo, quest.descricao, ""]
	var progress: Array = GameState.quests[id].progresso
	var objectives: Array = quest.objetivos
	for i in objectives.size():
		var needed := int(objectives[i].get("qtd", 1))
		var mark := "✓" if progress[i] >= needed else "•"
		lines.append("%s %s%s" % [mark, objectives[i].texto, " (%d/%d)" % [progress[i], needed] if needed > 1 else ""])
	if quest.has("entregar_a"):
		lines.append("• Voltar a %s" % Data.npcs.get(quest.entregar_a, {}).get("nome", "?"))
	var reward: Dictionary = quest.get("recompensa", {})
	var parts := []
	if reward.has("xp"):
		parts.append("%d XP" % reward.xp)
	for c in reward.get("moedas", {}):
		parts.append("%d %s" % [reward.moedas[c], Data.currency_name(c)])
	for item_id in reward.get("itens", {}):
		parts.append(Data.item(item_id).nome)
	if not parts.is_empty():
		lines.append("\nRecompensa: " + ", ".join(parts))
	_info.text = "\n".join(lines)
