class_name TouchJoystick
extends Control
## Joystick de toque. No modo "Livre" ele aparece onde o dedo tocar na metade esquerda;
## no modo "Fixo" fica sempre no canto. Tamanho e transparência vêm das Configurações.

const MARGIN := 18.0
const DEAD_ZONE := 0.15

var output := Vector2.ZERO
var _touch_index := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Recebe a soltura do dedo mesmo com o jogo pausado (diálogo, menu), senão o controle fica preso.
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(_reset_center)
	Settings.changed.connect(_reset_center)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reset_center()


func _radius() -> float:
	return Settings.joystick_radius()


func _home() -> Vector2:
	return Vector2(_radius() + MARGIN, size.y - _radius() - MARGIN)


func _reset_center() -> void:
	if _touch_index == -1:
		_center = _home()
		_knob = _center
		queue_redraw()


func _notification(what: int) -> void:
	# Se o app perde o foco no meio de um toque, a soltura nunca chega; solta o joystick aqui.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release()


func release() -> void:
	if _touch_index != -1 or output != Vector2.ZERO:
		_touch_index = -1
		output = Vector2.ZERO
		_reset_center()


func _can_start(pos: Vector2) -> bool:
	if Settings.get_value("joystick_modo") == 0:
		return pos.distance_to(_home()) <= _radius() * 1.6
	return pos.x < size.x * 0.45 and pos.y > 70


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or get_tree().paused:
		release()
		return
	if event is InputEventScreenTouch and event.canceled:
		release()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and _can_start(event.position):
			_touch_index = event.index
			if Settings.get_value("joystick_modo") == 1:
				_center = event.position
			_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)


func _update_knob(pos: Vector2) -> void:
	var offset := (pos - _center).limit_length(_radius())
	_knob = _center + offset
	var value := offset / _radius()
	output = Vector2.ZERO if value.length() < DEAD_ZONE else value
	queue_redraw()


func _draw() -> void:
	var alpha := Settings.controls_alpha()
	var active := _touch_index != -1
	draw_circle(_center, _radius(), Color(0, 0, 0, alpha * 0.45))
	draw_arc(_center, _radius(), 0, TAU, 48, Color(1, 1, 1, alpha + 0.1), 2.0)
	# Marcas das quatro direções.
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var tip: Vector2 = _center + dir * (_radius() - 6.0)
		var side: Vector2 = dir.orthogonal() * 4.0
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * 5.0 + side, tip - dir * 5.0 - side]), Color(1, 1, 1, alpha + 0.1))
	draw_circle(_knob, _radius() * 0.42, Color(1, 0.6, 0.2, minf(alpha + (0.35 if active else 0.15), 1.0)))
	draw_arc(_knob, _radius() * 0.42, 0, TAU, 32, Color(1, 1, 1, alpha + 0.2), 1.5)
