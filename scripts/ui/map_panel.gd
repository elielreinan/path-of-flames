class_name MapPanel
extends Control
## Mapa em duas abas: a área atual (com legenda) e o mapa geral, revelado conforme o progresso.

signal closed

var source: Node
## Aba aberta: "area" ou "mundo".
var tab := "area"

var _area_page: VBoxContainer
var _world_page: Control
var _tab_buttons := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Mapa", Vector2(456, 256))
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	w.box.add_child(tabs)
	for entry in [["area", Data.map(GameState.map_id).get("nome", "Esta área")], ["mundo", "Mapa geral"]]:
		var b := UiKit.button(entry[1], 9)
		var id: String = entry[0]
		b.pressed.connect(func(): _show(id))
		tabs.add_child(b)
		_tab_buttons[id] = b

	_area_page = VBoxContainer.new()
	w.box.add_child(_area_page)
	var map := MiniMap.new()
	map.full = true
	map.source = source
	map.custom_minimum_size = Vector2(440, 176)
	_area_page.add_child(map)
	map.set_rows(source.current_rows())
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 10)
	_area_page.add_child(legend)
	for entry in [[Color.WHITE, "Ifrit"], [Color(1, 0.85, 0.2), "Quer falar com você"], [Color(0.3, 0.7, 1.0), "Saída"],
			[Color(0.9, 0.25, 0.2), "Inimigo"], [Color(0.8, 0.1, 0.5), "Chefe"]]:
		var dot := ColorRect.new()
		dot.color = entry[0]
		dot.custom_minimum_size = Vector2(6, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		legend.add_child(dot)
		var text := UiKit.label(entry[1], 8, UiKit.MUTED)
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		legend.add_child(text)

	_world_page = VBoxContainer.new()
	w.box.add_child(_world_page)
	var world := WorldMap.new()
	world.custom_minimum_size = Vector2(440, 176)
	_world_page.add_child(world)
	var hint := UiKit.label("Arraste para mover. Regiões novas aparecem quando você as visita.", 8, UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_world_page.add_child(hint)
	_show(tab)


func _show(id: String) -> void:
	tab = id
	_area_page.visible = id == "area"
	_world_page.visible = id == "mundo"
	for key in _tab_buttons:
		var b: Button = _tab_buttons[key]
		if key == id:
			var on := UiKit.panel_style(Color(0.85, 0.5, 0.15))
			on.set_content_margin_all(3)
			b.add_theme_stylebox_override("normal", on)
			b.add_theme_stylebox_override("hover", on)
		else:
			b.remove_theme_stylebox_override("normal")
			b.remove_theme_stylebox_override("hover")
