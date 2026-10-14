class_name Prop
extends StaticBody2D
## Objeto do mapa com o qual dá para interagir: baú ou placa.

var kind := "placa"  # "bau" ou "placa"
var data := {}
var flag := ""
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	add_to_group("interagiveis")
	_sprite = Sprite2D.new()
	_sprite.offset = Vector2(0, -2)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 8)
	shape.shape = box
	add_child(shape)
	_update_sprite()


func is_open() -> bool:
	return kind == "bau" and GameState.has_flag(flag)


func _update_sprite() -> void:
	if kind == "bau":
		_sprite.texture = preload("res://assets/bau_aberto.png") if is_open() else preload("res://assets/bau.png")
	else:
		_sprite.texture = preload("res://assets/placa.png")


func open() -> void:
	Som.sfx("bau", -3.0)
	GameState.set_flag(flag)
	_update_sprite()
