class_name Ally
extends CharacterBody2D
## Aliado que segue o Ifrit e ataca inimigos sozinho. Configurado em npcs.json ("aliado").

const FOLLOW_DISTANCE := 20.0

var npc_id := ""
var data := {}
var player: Node2D
var slot := 0

var _cooldown := 0.0
var _sprite: Sprite2D
var _skin: SkinSprite
var _time := 0.0


func _ready() -> void:
	add_to_group("aliados")
	collision_layer = 0
	collision_mask = 1
	var sheet := SkinSprite.sheet_for("npcs", npc_id)
	if sheet:
		_skin = SkinSprite.create(sheet)
		_sprite = _skin
	else:
		_sprite = Sprite2D.new()
		_sprite.texture = CharacterSprite.make(data.aparencia)
		_sprite.offset = Vector2(0, -6)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_instance_valid(player):
		return
	var stats: Dictionary = data.aliado
	var ranged: bool = stats.tipo == "distancia"
	var enemy := _pick_target(float(stats.get("alcance_visao", 90)))
	var move := Vector2.ZERO
	var to_player := player.global_position - global_position
	# Nunca se afasta demais do Ifrit: longe demais, volta correndo (ou aparece do lado).
	if to_player.length() > 170.0:
		global_position = player.global_position + Vector2(-12 + slot * 24, 14)
	elif enemy and to_player.length() < 120.0:
		var to_enemy := enemy.global_position - global_position
		var reach := float(stats.alcance)
		var dist := to_enemy.length()
		if ranged:
			# Arqueiro: fica a uma boa distância, atrás do Ifrit se puder.
			if dist < reach * 0.5:
				move = -to_enemy.normalized() * 70.0
			elif dist > reach:
				move = to_enemy.normalized() * 75.0
			else:
				move = to_enemy.normalized().orthogonal() * (20.0 if slot == 0 else -20.0)
		else:
			# Corpo a corpo: chega pelo lado oposto ao do Ifrit para cercar o inimigo.
			var side := (enemy.global_position - player.global_position).normalized()
			var goal := enemy.global_position + side.rotated(0.7 if slot == 0 else -0.7) * (reach * 0.8)
			if dist > reach:
				move = (goal - global_position).normalized() * 80.0
		if dist <= reach and _cooldown <= 0.0:
			_cooldown = float(stats.recarga)
			_attack(enemy, to_enemy)
		_face(to_enemy)
	else:
		var spot := player.global_position + Vector2(-12 + slot * 24, 14)
		var to_spot := spot - global_position
		if to_spot.length() > 6:
			move = to_spot.normalized() * minf(95.0, to_spot.length() * 4.0)
			_face(to_spot)
	velocity = move + _separation() * 30.0
	move_and_slide()
	_update_swim()
	if not _swimming and not _skin:
		_sprite.position.y = -absf(sin(_time * 12.0)) if velocity.length() > 5.0 else 0.0


## Escolhe o alvo: primeiro quem está perto do Ifrit (protege o herói), depois o mais próximo.
func _pick_target(radius: float) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		var d_self: float = enemy.global_position.distance_to(global_position)
		if d_self > radius:
			continue
		var d_player: float = enemy.global_position.distance_to(player.global_position)
		var score := d_self + d_player * 0.8
		if score < best_score:
			best = enemy
			best_score = score
	return best


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("aliados"):
		if other != self and other.global_position.distance_to(global_position) < 12.0:
			push += (global_position - other.global_position).normalized()
	if is_instance_valid(player) and player.global_position.distance_to(global_position) < 10.0:
		push += (global_position - player.global_position).normalized()
	return push


var _swimming := false


## Nada como o Ifrit: só a parte de cima aparece e surgem ondinhas.
func _update_swim() -> void:
	var tiles := get_tree().get_first_node_in_group("terreno") as TileLayer
	var now := tiles != null and tiles.terrain_at(global_position) == TileLayer.WATER
	if now != _swimming:
		_swimming = now
		if _skin:
			_skin.swimming = now
		else:
			_sprite.region_enabled = now
			_sprite.region_rect = Rect2(0, 0, 16, 9)
			_sprite.offset = Vector2(0, -5.5) if now else Vector2(0, -6)
	if _swimming:
		if not _skin:
			_sprite.position.y = sin(_time * 4.0 + slot) * 0.8
		queue_redraw()


func _draw() -> void:
	if _swimming:
		var wave := 0.5 + 0.5 * sin(_time * 5.0 + slot)
		draw_arc(Vector2.ZERO, 7.0 + wave * 2.0, PI, TAU, 12, Color(1, 1, 1, 0.6 - wave * 0.3), 1.0)


func _attack(enemy: Node2D, to_enemy: Vector2) -> void:
	if _skin:
		_skin.set_direction(to_enemy)
		_skin.play("golpe", true)
	var damage := int(data.aliado.dano) + int(GameState.level / 3.0)
	if data.aliado.tipo == "distancia":
		var arrow := Projectile.new()
		arrow.texture = load(data.aliado.get("projetil", "res://assets/flecha.png"))
		arrow.spin = data.aliado.has("projetil")
		arrow.direction = to_enemy.normalized()
		arrow.speed = 200.0
		arrow.damage = damage
		arrow.global_position = global_position + Vector2(0, -6)
		get_parent().add_child(arrow)
	else:
		enemy.take_damage(damage, global_position)


func _face(direction: Vector2) -> void:
	if _skin:
		_skin.set_direction(direction)
	elif absf(direction.x) > 1.0:
		_sprite.flip_h = direction.x < 0


func _nearest_enemy(radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := radius
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		var distance: float = enemy.global_position.distance_to(global_position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best
