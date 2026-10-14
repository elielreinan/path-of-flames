class_name Pickup
extends Area2D
## Item, moeda ou coração no chão, recolhido ao encostar.
## Quando cai de um inimigo, salta para fora dele; de perto, é puxado até o Ifrit.

const MAGNET_RANGE := 26.0
const MAGNET_SPEED := 140.0

var item_id := ""
var currency := ""
var amount := 1
## Vida recuperada na hora (corações).
var heal := 0
var flag := ""  # se definido, só pode ser pego uma vez
var texture: Texture2D
## Itens raros brilham.
var rare := false
## Para onde o item salta ao cair (relativo à posição inicial).
var toss := Vector2.ZERO
var _time := 0.0
var _toss_time := 0.0
var _start := Vector2.ZERO
var _sprite: Sprite2D
var _taken := false


func _ready() -> void:
	collision_layer = 1 << 3
	collision_mask = 1 << 1
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	add_child(_sprite)
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)
	_time = randf() * 3.0
	_start = position
	# Recém-caído: só pode ser pego depois de pousar.
	if toss != Vector2.ZERO:
		_toss_time = 0.35
		monitoring = false


func _process(delta: float) -> void:
	_time += delta
	if _toss_time > 0.0:
		_toss_time = maxf(_toss_time - delta, 0.0)
		var t := 1.0 - _toss_time / 0.35
		position = _start + toss * t
		_sprite.position.y = -sin(t * PI) * 10.0 - 2.0
		if _toss_time == 0.0:
			monitoring = true
		return
	_sprite.position.y = sin(_time * 5.0) * 1.5 - 2.0
	# Ímã: itens que caíram de inimigos (sem flag) vão até o Ifrit quando ele chega perto.
	if flag == "" and not _taken:
		var player := get_tree().get_first_node_in_group("jogador") as Node2D
		if player and player.get("controllable") and player.global_position.distance_to(global_position) < MAGNET_RANGE:
			global_position = global_position.move_toward(player.global_position, MAGNET_SPEED * delta)
	if rare:
		queue_redraw()


func _draw() -> void:
	if rare:
		var glow := 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(_sprite.position, 8.0 + glow * 2.0, Color(1, 0.9, 0.4, 0.18 + glow * 0.12))
		for i in 4:
			var a := _time * 2.0 + i * TAU / 4.0
			var p := _sprite.position + Vector2.from_angle(a) * (10.0 + glow * 2.0)
			draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 0.8, 0.8))


func _on_body_entered(body: Node) -> void:
	if not body is Player or _taken:
		return
	_taken = true
	Som.sfx("cura" if heal > 0 else ("moeda" if currency != "" else "pegar"), -5.0)
	if heal > 0:
		GameState.heal(heal)
	elif currency != "":
		GameState.add_money(currency, amount)
	elif item_id != "":
		GameState.add_item(item_id, amount)
	if flag != "":
		GameState.set_flag(flag)
	queue_free()
