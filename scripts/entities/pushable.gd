class_name Pushable
extends StaticBody2D
## Pedra que o Ifrit empurra andando contra ela. Anda um tile por vez, só para chão livre.
## A posição fica salva numa flag (lista [x, y]) para continuar no lugar depois.

const TILE := 16
const PUSH_TIME := 0.45

var flag := ""
var cell := Vector2i.ZERO
var _push := 0.0
var _push_dir := Vector2i.ZERO
var _moving := false
var _stone: Texture2D = load("res://assets/pedra_empurravel.png") if ResourceLoader.exists("res://assets/pedra_empurravel.png") else null


func _ready() -> void:
	add_to_group("empurraveis")
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(14, 14)
	shape.shape = box
	add_child(shape)
	position = Vector2(cell) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


func _physics_process(delta: float) -> void:
	if _moving:
		return
	var player := get_tree().get_first_node_in_group("jogador") as Player
	if player == null or not player.controllable:
		_push = 0.0
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if player.joystick:
		input += player.joystick.output
	var to_me := global_position - player.global_position
	var dir := Vector2i.ZERO
	# Encostado num dos lados e empurrando na direção da pedra.
	if absf(to_me.y) < 9.0 and absf(to_me.x) < 15.0 and input.x * signf(to_me.x) > 0.5:
		dir = Vector2i(int(signf(to_me.x)), 0)
	elif absf(to_me.x) < 9.0 and absf(to_me.y) < 16.0 and input.y * signf(to_me.y) > 0.5:
		dir = Vector2i(0, int(signf(to_me.y)))
	if dir == Vector2i.ZERO or dir != _push_dir:
		_push = 0.0
		_push_dir = dir
		return
	_push += delta
	if _push >= PUSH_TIME:
		_push = 0.0
		_try_move(dir)


func _try_move(dir: Vector2i) -> void:
	var target := cell + dir
	var tiles := get_tree().get_first_node_in_group("terreno") as TileLayer
	if tiles == null or tiles.is_solid(target) or not tiles.terrain_at(Vector2(target) * TILE + Vector2(8, 8)) in [".", ",", ":"]:
		return
	for other in get_tree().get_nodes_in_group("empurraveis"):
		if other != self and other.cell == target:
			return
	cell = target
	_moving = true
	Som.sfx("empurrar", -6.0)
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(cell) * TILE + Vector2(TILE / 2.0, TILE / 2.0), 0.3).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	_moving = false
	if flag != "":
		GameState.set_flag(flag, [cell.x, cell.y])


func _draw() -> void:
	# Pedra desenhada (fio de Artes), pé em (8,14); se faltar, a redonda em código.
	if _stone:
		draw_texture(_stone, Vector2(-8, -14 + 6))
		return
	draw_circle(Vector2(0, 4), 7.5, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, 0), 7.5, Color(0.45, 0.38, 0.32))
	draw_circle(Vector2(-2, -2), 5.0, Color(0.58, 0.5, 0.42))
	draw_line(Vector2(-3, 1), Vector2(1, 4), Color(0.3, 0.25, 0.2), 1.0)
	draw_line(Vector2(2, -4), Vector2(4, -1), Color(0.3, 0.25, 0.2), 1.0)
