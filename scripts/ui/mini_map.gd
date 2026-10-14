class_name MiniMap
extends Control
## Mapa desenhado a partir das linhas do mapa (uma cor por tile).
## Modo mini: mostra a região em volta do Ifrit. Modo completo: o mapa inteiro.

signal pressed

const PX_PER_TILE := 2.0

## Objeto que responde minimap_markers() (o World).
var source: Node
var full := false

static var _tile_colors: Dictionary = {}
var _texture: ImageTexture
var _map_size := Vector2i.ZERO
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


## Cor média de cada tile do atlas, calculada uma vez.
static func _colors() -> Dictionary:
	if _tile_colors.is_empty():
		var atlas: Image = TileLayer.ATLAS.get_image()
		if atlas.is_compressed():
			atlas.decompress()
		for i in TileLayer.TILE_CHARS.length():
			var sum := Color(0, 0, 0, 0)
			for y in TileLayer.TILE:
				for x in TileLayer.TILE:
					sum += atlas.get_pixel(i * TileLayer.TILE + x, y)
			var avg := sum / float(TileLayer.TILE * TileLayer.TILE)
			var ch := TileLayer.TILE_CHARS[i]
			if TileLayer.SOLID.contains(ch):
				avg = avg.darkened(0.25)
			avg.a = 1.0
			_tile_colors[ch] = avg
	return _tile_colors


func set_rows(rows: Array) -> void:
	var colors := _colors()
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	_map_size = Vector2i(maxi(width, 1), maxi(rows.size(), 1))
	var image := Image.create(_map_size.x, _map_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 1))
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			image.set_pixel(x, y, colors.get(row[x], Color.BLACK))
	_texture = ImageTexture.create_from_image(image)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
	if _texture == null or source == null:
		return
	var markers: Dictionary = source.minimap_markers()
	var player_tile: Vector2 = markers.get("jogador", Vector2.ZERO)
	var scale_px: float
	var origin: Vector2
	if full:
		scale_px = minf(size.x / _map_size.x, size.y / _map_size.y)
		origin = (size - Vector2(_map_size) * scale_px) / 2.0
	else:
		scale_px = PX_PER_TILE
		origin = size / 2.0 - player_tile * scale_px
		# Não deixa mostrar fora do mapa quando o mapa é maior que o quadro.
		var map_px := Vector2(_map_size) * scale_px
		for axis in 2:
			if map_px[axis] > size[axis]:
				origin[axis] = clampf(origin[axis], size[axis] - map_px[axis], 0.0)
			else:
				origin[axis] = (size[axis] - map_px[axis]) / 2.0
	draw_texture_rect(_texture, Rect2(origin, Vector2(_map_size) * scale_px), false)
	var dot := maxf(scale_px * 0.9, 1.5)
	for exit_tile in markers.get("saidas", []):
		draw_rect(Rect2(origin + exit_tile * scale_px - Vector2(dot, dot) / 2.0, Vector2(dot, dot)), Color(0.3, 0.7, 1.0))
	for enemy_tile in markers.get("inimigos", []):
		draw_circle(origin + enemy_tile * scale_px, dot * 0.6, Color(0.9, 0.25, 0.2))
	for npc_tile in markers.get("npcs", []):
		draw_circle(origin + npc_tile * scale_px, dot * 0.6, Color(0.85, 0.85, 0.85))
	for npc_tile in markers.get("importantes", []):
		draw_circle(origin + npc_tile * scale_px, dot, Color(1, 0.85, 0.2))
	if markers.has("chefe"):
		draw_circle(origin + markers.chefe * scale_px, dot * 1.5, Color(0.8, 0.1, 0.5))
	var blink := 0.6 + 0.4 * sin(_time * 6.0)
	draw_circle(origin + player_tile * scale_px, dot * 1.2 + 0.5, Color(0, 0, 0))
	draw_circle(origin + player_tile * scale_px, dot * 1.2, Color(1, 1, 1, blink))
	var style := UiKit.panel_style(Color(0, 0, 0, 0))
	draw_style_box(style, Rect2(Vector2.ZERO, size))
