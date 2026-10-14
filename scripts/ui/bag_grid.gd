class_name BagGrid
extends Control
## Grade da bolsa: cada item ocupa células conforme o tamanho (espada 1x3, armadura 2x2...).
## Tocar numa célula emite cell_tapped; quem decide o que fazer é o InventoryPanel.

signal cell_tapped(cell: Vector2i)

const CELL := 24.0

var selected: Dictionary = {}
## "mover": pinta de verde onde o item selecionado cabe.
var mode := ""
var move_rotated := false

static var _textures := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameState.changed.connect(_resize)
	_resize()


func _resize() -> void:
	custom_minimum_size = Vector2(GameState.bag_size()) * CELL
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := Vector2i((event.position / CELL).floor())
		if cell.x >= 0 and cell.y >= 0 and cell.x < GameState.bag_size().x and cell.y < GameState.bag_size().y:
			cell_tapped.emit(cell)
		accept_event()


## grid = desenho grande da bolsa (itens com "tam"), quando existe.
static func _slot(name: String) -> Texture2D:
	var path := "res://assets/ui/paineis/%s.png" % name
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


static func texture_for(id: String, grid := false) -> Texture2D:
	var item: Dictionary = Data.item(id)
	var path: String = item.get("sprite_grade", item.get("sprite", "")) if grid else item.get("sprite", "")
	if path == "":
		return null
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]


## Desenha o ícone de um item dentro de um retângulo, girando 90° quando preciso.
static func draw_item(canvas: CanvasItem, id: String, rect: Rect2, rotated := false) -> void:
	var tex := texture_for(id, true)
	var inner := rect.grow(-2)
	if tex == null:
		canvas.draw_rect(inner, Color(0.45, 0.35, 0.25))
		var font := ThemeDB.fallback_font
		canvas.draw_string(font, inner.position + Vector2(2, inner.size.y / 2 + 3), Data.item(id).nome.left(3),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		return
	var box := Vector2(inner.size.y, inner.size.x) if rotated else inner.size
	var tex_size := tex.get_size()
	var scale := minf(box.x / tex_size.x, box.y / tex_size.y)
	var draw_size := tex_size * scale
	canvas.draw_set_transform(inner.get_center(), -PI / 2.0 if rotated else 0.0, Vector2.ONE)
	canvas.draw_texture_rect(tex, Rect2(-draw_size / 2.0, draw_size), false)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	var size_cells := GameState.bag_size()
	var font := get_theme_default_font()
	for y in size_cells.y:
		for x in size_cells.x:
			var r := Rect2(Vector2(x, y) * CELL, Vector2(CELL, CELL))
			var color := Color(0.2, 0.15, 0.12)
			var slot := "slot_normal"
			if mode == "mover" and not selected.is_empty() and GameState.fits(selected.id, Vector2i(x, y), move_rotated, selected):
				color = Color(0.2, 0.4, 0.2)
				slot = "slot_mover"
			var tex := _slot(slot)
			if tex:
				draw_texture_rect(tex, r, false)
			else:
				draw_rect(r.grow(-1), color)
	for entry in GameState.grid:
		var rect := Rect2(Vector2(GameState.entry_rect(entry).position) * CELL, Vector2(GameState.entry_rect(entry).size) * CELL)
		var bg := Color(0.38, 0.28, 0.2, 0.6) if not Data.item(entry.id).get("raro", false) else Color(0.42, 0.3, 0.48, 0.7)
		draw_rect(rect.grow(-1), bg)
		BagGrid.draw_item(self, entry.id, rect, entry.get("r", false))
		if int(entry.n) > 1:
			var text := str(entry.n)
			var pos := rect.end - Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 2, 2)
			draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color.BLACK)
			draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		var delta = GameState.equip_delta(entry.id)
		if delta != null:
			CompareMark.paint(self, Rect2(rect.position + Vector2(rect.size.x - 10, 2), Vector2(8, 8)), delta)
		if entry.id == GameState.quick_item:
			draw_circle(rect.position + Vector2(4, 4), 2.5, Color(0.3, 0.9, 0.4))
		if entry == selected:
			draw_rect(rect.grow(-1), UiKit.ACCENT, false, 2.0)
