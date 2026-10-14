class_name WorldMap
extends Control
## Mapa geral: as regiões aparecem conforme o Ifrit as visita. Vizinhas ainda não visitadas
## aparecem como "???". Arraste para mover o mapa.

const MIN_UNIT := 10.0
const MAX_UNIT := 22.0
const COLORS := {
	"cidade": Color(0.78, 0.56, 0.32), "deserto": Color(0.86, 0.7, 0.42), "caverna": Color(0.36, 0.3, 0.28),
	"agua": Color(0.3, 0.55, 0.75), "rocha": Color(0.6, 0.55, 0.5), "neve": Color(0.75, 0.78, 0.82),
	"cinzas": Color(0.4, 0.36, 0.4),
}

var _offset := Vector2.ZERO
var _unit := 14.0
var _dragging := false
var _links: Array = []  # [região_a, região_b]
var _time := 0.0
var _here := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_here = Data.region_of(GameState.map_id)
	var seen := {}
	for id in _regions():
		for warp in Data.map(id).get("saidas", []):
			var other := Data.region_of(warp.mapa)
			if other == "" or other == id:
				continue
			var key := [id, other] if id < other else [other, id]
			if not seen.has(str(key)):
				seen[str(key)] = true
				_links.append(key)
	resized.connect(_center)
	_center.call_deferred()


func _regions() -> Dictionary:
	return Data.world.get("regioes", {})


func _rect(id: String) -> Rect2:
	var r: Array = _regions()[id].rect
	return Rect2(Vector2(r[0], r[1]) * _unit + _offset, Vector2(r[2], r[3]) * _unit)


func _known(id: String) -> bool:
	return GameState.visited.has(id)


## Vizinha de uma região visitada: aparece como "???".
func _hinted(id: String) -> bool:
	if _known(id):
		return false
	for link in _links:
		if (link[0] == id and _known(link[1])) or (link[1] == id and _known(link[0])):
			return true
	return false


## Enquadra tudo o que já aparece no mapa; se não couber, centraliza onde o Ifrit está.
func _center() -> void:
	var bounds := Rect2()
	var first := true
	for id in _regions():
		if not (_known(id) or _hinted(id)):
			continue
		var r: Array = _regions()[id].rect
		var rect := Rect2(r[0], r[1], r[2], r[3])
		bounds = rect if first else bounds.merge(rect)
		first = false
	if first or size.x <= 0.0:
		return
	# Folga para os nomes embaixo e dos lados.
	bounds = bounds.grow_individual(2.0, 1.0, 2.0, 1.6)
	_unit = clampf(minf(size.x / bounds.size.x, size.y / bounds.size.y), MIN_UNIT, MAX_UNIT)
	_offset = size / 2.0 - bounds.get_center() * _unit
	if (bounds.size * _unit).x > size.x or (bounds.size * _unit).y > size.y:
		if _here != "" and _regions().has(_here):
			_offset = Vector2.ZERO
			_offset = size / 2.0 - _rect(_here).get_center()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_offset += event.relative
		accept_event()
	elif event is InputEventScreenDrag:
		_offset += event.relative
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.12, 0.09, 0.07))
	var font := get_theme_default_font()
	for link in _links:
		var a_known := _known(link[0])
		var b_known := _known(link[1])
		if not (a_known or b_known):
			continue
		var a := _rect(link[0]).get_center()
		var b := _rect(link[1]).get_center()
		var color := Color(0.85, 0.7, 0.45, 0.8) if a_known and b_known else Color(0.85, 0.7, 0.45, 0.3)
		draw_line(a, b, color, 2.0 if a_known and b_known else 1.0)
	for id in _regions():
		var r := _rect(id)
		if _known(id):
			var color: Color = COLORS.get(_regions()[id].tipo, Color.GRAY)
			draw_rect(r, color)
			draw_rect(r, color.darkened(0.45), false, 1.0)
		elif _hinted(id):
			draw_rect(r, Color(0.3, 0.25, 0.2, 0.6))
			draw_rect(r, Color(0.6, 0.5, 0.35, 0.6), false, 1.0)
	# Nomes por cima de tudo, para não serem cobertos por outra região.
	for id in _regions():
		var r := _rect(id)
		var text := ""
		if _known(id):
			text = _regions()[id].nome
		elif _hinted(id):
			text = "???"
		if text == "":
			continue
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
		var pos := Vector2(r.get_center().x - width / 2.0, r.end.y + 9)
		# Estradas em pé: o nome vai do lado, para não cobrir a região de baixo.
		if r.size.y > r.size.x * 1.5:
			pos = Vector2(r.end.x + 4, r.get_center().y + 3)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 3, Color(0, 0, 0, 0.9))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE if _known(id) else Color(0.7, 0.65, 0.55))
	if _here != "" and _regions().has(_here):
		var r := _rect(_here)
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		draw_rect(r.grow(2.0 + pulse * 1.5), Color(1, 1, 1, 0.5 + pulse * 0.5), false, 1.5)
		draw_circle(r.get_center(), 3.0, Color.WHITE)
		draw_circle(r.get_center(), 1.8, Color(0.9, 0.2, 0.1))
