class_name InventoryPanel
extends Control
## Bolsa estilo Resident Evil: equipamento (arma e armadura) separado dos suprimentos,
## grade onde cada item ocupa seu tamanho, girar, mover, combinar, organizar e baú.

signal closed

var _tab := "bolsa"
var _grid: BagGrid
var _bag_page: HBoxContainer
var _list_page: VBoxContainer
var _list: VBoxContainer
var _info: Label
var _compare: HBoxContainer
var _compare_mark: CompareMark
var _compare_label: Label
var _stats: Label
var _money: Label
var _actions: GridContainer
var _tabs := {}
var _slots := {}
## O que está selecionado: {"tipo": "grade", "entry": {...}} | {"tipo": "slot", "slot": "weapon"} |
## {"tipo": "importante"|"bau", "id": "..."}
var _sel := {}
var _mode := ""


class SlotView extends Control:
	signal tapped
	var slot := ""
	var title := ""
	var active := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		GameState.changed.connect(queue_redraw)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit()
			accept_event()

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.MUTED)
		var box := Rect2(0, 11, size.x, size.y - 11)
		draw_rect(box, Color(0.2, 0.15, 0.12))
		draw_rect(box, UiKit.ACCENT if active else UiKit.BORDER.darkened(0.3), false, 2.0 if active else 1.0)
		var id: String = GameState.get(slot)
		if id == "":
			draw_string(font, box.position + Vector2(4, box.size.y / 2 + 3), "vazio", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.MUTED)
		else:
			# Espadas ficam deitadas no slot para caber melhor.
			BagGrid.draw_item(self, id, box, GameState.item_size(id).y > GameState.item_size(id).x)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Bolsa", Vector2(464, 258), "bolsa")
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	w.box.add_child(top)
	for entry in [["bolsa", "Bolsa"], ["importante", "Importantes"], ["bau", "Baú"]]:
		var b := UiKit.button(entry[1], 9)
		var id: String = entry[0]
		b.pressed.connect(func(): _show(id))
		top.add_child(b)
		_tabs[id] = b
	_money = UiKit.label("", 8, UiKit.MUTED)
	_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money.autowrap_mode = TextServer.AUTOWRAP_OFF
	top.add_child(_money)

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 6)
	w.box.add_child(main)

	# Coluna do equipamento e atributos.
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 86
	left.add_theme_constant_override("separation", 3)
	main.add_child(left)
	for entry in [["weapon", "Arma"], ["armor", "Armadura"]]:
		var s := SlotView.new()
		s.slot = entry[0]
		s.title = entry[1]
		s.custom_minimum_size = Vector2(86, 40)
		var slot_id: String = entry[0]
		s.tapped.connect(func(): _select({"tipo": "slot", "slot": slot_id}))
		left.add_child(s)
		_slots[slot_id] = s
	_stats = UiKit.label("", 8, UiKit.MUTED)
	_stats.autowrap_mode = TextServer.AUTOWRAP_OFF
	left.add_child(_stats)

	# Centro: grade ou lista.
	var center := VBoxContainer.new()
	center.custom_minimum_size.x = 196
	main.add_child(center)
	_bag_page = HBoxContainer.new()
	center.add_child(_bag_page)
	_grid = BagGrid.new()
	_grid.cell_tapped.connect(_on_cell)
	_bag_page.add_child(_grid)
	_list_page = VBoxContainer.new()
	center.add_child(_list_page)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(196, 170)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_page.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	# Direita: detalhes e ações.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	_info = UiKit.label("", 8)
	_info.custom_minimum_size = Vector2(150, 92)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_info)
	_compare = HBoxContainer.new()
	_compare.add_theme_constant_override("separation", 4)
	_compare.visible = false
	right.add_child(_compare)
	_compare_mark = CompareMark.make(0, 9.0)
	_compare_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_compare.add_child(_compare_mark)
	_compare_label = UiKit.label("", 8)
	_compare_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_compare_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compare.add_child(_compare_label)
	_actions = GridContainer.new()
	_actions.columns = 2
	_actions.add_theme_constant_override("h_separation", 3)
	_actions.add_theme_constant_override("v_separation", 3)
	right.add_child(_actions)

	GameState.changed.connect(_refresh)
	_show("bolsa")


func _show(tab: String) -> void:
	_tab = tab
	_sel = {}
	_mode = ""
	for key in _tabs:
		var b: Button = _tabs[key]
		if key == tab:
			var on := UiKit.selected_style()
			b.add_theme_stylebox_override("normal", on)
			b.add_theme_stylebox_override("hover", on)
		else:
			b.add_theme_stylebox_override("normal", UiKit.button_box())
			b.add_theme_stylebox_override("hover", UiKit.button_box())
	_refresh()


func _refresh() -> void:
	if not is_inside_tree():
		return
	_bag_page.visible = _tab == "bolsa"
	_list_page.visible = _tab != "bolsa"
	# Seleção que deixou de existir (item usado até acabar).
	if _sel.get("tipo") == "grade" and not GameState.grid.has(_sel.entry):
		_sel = {}
		_mode = ""
	if _sel.get("tipo") in ["importante", "bau"] and GameState.item_count(_sel.id) <= 0:
		_sel = {}
	_grid.selected = _sel.get("entry", {}) if _sel.get("tipo") == "grade" else {}
	_grid.mode = _mode
	_grid.queue_redraw()
	for key in _slots:
		_slots[key].active = _sel.get("slot", "") == key
		_slots[key].queue_redraw()

	var money := []
	for currency in GameState.wallet:
		money.append("%s %d" % [Data.currency_name(currency), GameState.money(currency)])
	_money.text = "   ".join(money)
	_stats.text = "Nv %d\nVida %d/%d\nAtaque %d  Defesa %d\nMagia %d\nHonra %d\n%s\n%s" % [
		GameState.level, GameState.hp, GameState.max_hp(), GameState.attack_power(), GameState.defense(),
		GameState.magic_power(), GameState.honra, GameState.honor_title(), GameState.rank()]

	if _tab != "bolsa":
		_fill_list()
	_fill_info()


func _fill_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	if _tab == "bau" and not GameState.storage_open():
		_list.add_child(_wrap(UiKit.label("O baú só abre em cidades e dentro das casas.", 9, UiKit.MUTED)))
		return
	var source: Dictionary = GameState.storage if _tab == "bau" else GameState.inventory
	var ids := source.keys().filter(func(id): return (_tab == "bau") or GameState.is_key_item(id))
	ids.sort_custom(func(a, b): return Data.item(a).nome < Data.item(b).nome)
	for id in ids:
		var b := UiKit.button("%s x%d" % [Data.item(id).nome, source[id]])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var tipo := _tab
		var item_id: String = id
		b.pressed.connect(func(): _select({"tipo": tipo, "id": item_id}))
		_list.add_child(b)
	if ids.is_empty():
		_list.add_child(UiKit.label("Nada aqui ainda." if _tab == "bau" else "Nenhum item importante.", 9, UiKit.MUTED))


func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 190
	return l


func _selected_id() -> String:
	match _sel.get("tipo", ""):
		"grade": return _sel.entry.id
		"slot": return GameState.get(_sel.slot)
		"importante", "bau": return _sel.id
	return ""


func _fill_info() -> void:
	_compare.visible = false
	for child in _actions.get_children():
		child.queue_free()
	var id := _selected_id()
	if _mode == "mover":
		_info.text = "Toque onde quer colocar %s. Verde = cabe." % Data.item(id).nome
		_action("Girar", func(): _grid.move_rotated = not _grid.move_rotated; _refresh())
		_action("Cancelar", func(): _mode = ""; _refresh())
		return
	if _mode == "combinar":
		_info.text = "Toque no item para combinar com %s." % Data.item(id).nome
		_action("Cancelar", func(): _mode = ""; _refresh())
		return
	if id == "":
		var size := GameState.bag_size()
		match _tab:
			"bolsa": _info.text = "Toque num item.\nBolsa %d x %d.\nArma e armadura ficam fora da grade." % [size.x, size.y]
			"importante": _info.text = "Itens de missão. Não ocupam espaço na bolsa."
			"bau": _info.text = "O que não cabe na bolsa fica aqui. Toque num item para pegar."
		if _tab == "bolsa":
			_action("Organizar", func(): GameState.organize(); _info.text = "Bolsa organizada.")
		return
	var data := Data.item(id)
	var text := "%s\n%s" % [data.nome, data.get("descricao", "")]
	if data.has("cura"):
		text += "\nRecupera %d de vida." % data.cura
	if data.has("dano"):
		text += "\nDano +%d." % data.dano
	if data.has("defesa"):
		text += "\nDefesa +%d." % data.defesa
	# Comparação com o que está equipado (não vale para o próprio slot).
	var delta = GameState.equip_delta(id) if _sel.tipo != "slot" else null
	if delta != null:
		_compare.visible = true
		_compare_mark.delta = delta
		_compare_label.text = "Melhor que o equipado (+%d)" % delta if delta > 0 else "Pior que o equipado (%d)" % delta if delta < 0 else "Igual ao equipado"
		_compare_label.add_theme_color_override("font_color", CompareMark.color_for(delta))
	_info.text = text
	match _sel.tipo:
		"grade":
			var entry: Dictionary = _sel.entry
			match data.get("tipo"):
				"consumivel":
					_action("Usar", func(): _info.text = GameState.use_item(id))
					if id != GameState.quick_item:
						_action("Atalho", func(): GameState.set_quick_item(id); _refresh())
				"arma", "armadura":
					_action("Equipar", func(): _info.text = GameState.equip(id))
			_action("Mover", func():
				_mode = "mover"
				_grid.move_rotated = entry.get("r", false)
				_refresh())
			_action("Girar", func():
				if not GameState.move_entry(entry, Vector2i(entry.x, entry.y), not entry.get("r", false)):
					_info.text = "Não cabe girado aqui. Use Mover."
				_refresh())
			_action("Combinar", func(): _mode = "combinar"; _refresh())
			if GameState.storage_open():
				_action("Pro baú", func(): GameState.store_entry(entry); _sel = {}; _refresh())
		"slot":
			_action("Tirar", func():
				var msg := GameState.unequip(_sel.slot)
				_refresh()
				_info.text = msg)
		"bau":
			_action("Pegar", func():
				var msg := GameState.take_from_storage(id)
				_refresh()
				_info.text = msg)


func _action(text: String, callback: Callable) -> void:
	var b := UiKit.button(text, 8)
	b.custom_minimum_size = Vector2(72, 20)
	b.pressed.connect(callback)
	_actions.add_child(b)


func _select(sel: Dictionary) -> void:
	_sel = sel
	_mode = ""
	_refresh()


func _on_cell(cell: Vector2i) -> void:
	var entry := GameState.entry_at(cell)
	if _mode == "mover":
		var moving: Dictionary = _sel.entry
		if GameState.move_entry(moving, cell, _grid.move_rotated):
			_mode = ""
			_refresh()
		else:
			_info.text = "Não cabe aí."
		return
	if _mode == "combinar":
		_mode = ""
		if entry.is_empty():
			_refresh()
			return
		var msg := GameState.combine(_sel.entry, entry)
		_sel = {}
		_refresh()
		_info.text = msg
		return
	if entry.is_empty():
		_select({})
	else:
		_select({"tipo": "grade", "entry": entry})
