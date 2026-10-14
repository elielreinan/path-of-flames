class_name Enemy
extends CharacterBody2D
## Inimigo configurado por data/inimigos.json.

signal died(enemy: Enemy)

const CONTACT_RADIUS := 11.0
## Camada das bordas de água: bloqueia quem anda, mas não quem voa nem o Ifrit (que nada).
const WATER_LAYER := 1 << 4
## Distância até o Ifrit em que aparece a barra de vida, e (menor) o nome.
const LABEL_RANGE := 90.0
const NAME_RANGE := 40.0

## Vida (fração) abaixo da qual uma fera domável aceita a isca.
const TAME_HP := 0.4

var type_id := ""
var data := {}
## Dificuldade (o jogo estava fácil demais): vida e dano extras dos inimigos comuns.
const HP_MULT := 1.25
const DAMAGE_MULT := 1.2
var hp := 3
var max_hp := 3
## Dano de contato já com o bônus de dificuldade (sobe a cada chefe vencido).
var damage := 1
var target: Node2D
var hit_radius := 0.0
var body_radius := 6.0
## Nome e vida em cima da cabeça (o chefe usa a barra do HUD).
var show_overhead := true

var _home := Vector2.ZERO
var _wander := Vector2.ZERO
var _wander_timer := 0.0
var _knockback := Vector2.ZERO
## Depois de encostar no Ifrit o inimigo recua um pouco antes de voltar (não fica grudado).
var _recoil := 0.0
## IA: "cacador" cerca e dá bote, "matilha" cerca em grupo, "atirador" mantém distância e atira,
## "tanque" é lento e pesado, "voar" ziguezagueia. Feras com "foge" correm quando estão quase mortas.
var _flank := 0.0
var _attack_state := ""
var _state_timer := 0.0
var _attack_cd := 0.0
var _lunge_dir := Vector2.ZERO
var _shoot_cd := 0.0
var _stun := 0.0
var _flash_timer := 0.0
var _show_bar_timer := 0.0
var _time := 0.0
var _sprite: Sprite2D
var status := StatusEffects.new()
var _idle_texture: Texture2D
## Skin Sunnyside dos inimigos humanos (null nos bichos e em quem não tem arquivo).
var _skin: SkinSprite
## Criatura desenhada (bichos e chefes); null nos humanos e em quem não tem folha.
var _creature: CreatureSprite
var _walk_frames: Array[Texture2D] = []


func setup(id: String) -> void:
	type_id = id
	data = Data.enemies[id]
	var tier := GameState.boss_tier()
	# Dificuldade: inimigos com ~25% mais vida e ~20% mais dano (chefes: mais vida, ver Boss.hp_mult).
	var training: bool = data.get("treino", false)
	max_hp = int(ceil(float(data.hp) * (1.0 + 0.1 * tier) * (1.0 if training else hp_mult())))
	hp = max_hp
	var base_damage := float(data.dano) * (1.0 + 0.06 * tier) * level_gap_damage()
	damage = maxi(int(ceil(base_damage)), roundi(base_damage * DAMAGE_MULT)) if data.dano > 0 else 0


## Nível importa: inimigo de nível maior que o Ifrit bate mais forte...
func level_gap_damage() -> float:
	return clampf(1.0 + 0.05 * (int(data.get("nivel", 1)) - GameState.level), 0.5, 2.0)


## ...e apanha menos.
func level_gap_defense() -> float:
	if data.get("treino", false):
		return 1.0
	return clampf(1.0 - 0.03 * (int(data.get("nivel", 1)) - GameState.level), 0.4, 1.5)


## Multiplicador de vida por dificuldade (o chefe sobrescreve).
func hp_mult() -> float:
	return HP_MULT


func _ready() -> void:
	add_to_group("inimigos")
	collision_layer = 1 << 2
	# Esbarra nas paredes, nos outros inimigos e no Ifrit; quem anda não entra na água.
	collision_mask = 1 | (1 << 1) | (1 << 2)
	if data.get("comportamento", "") != "voar":
		collision_mask |= WATER_LAYER
	_home = position
	_flank = randf_range(-1.2, 1.2)
	_attack_cd = randf_range(0.5, 1.5)
	_shoot_cd = randf_range(1.0, 2.0)
	var sheet: Texture2D = SkinSprite.sheet_for("inimigos", type_id) if data.has("aparencia") else null
	var creature_id: String = data.get("criatura", "")
	if sheet:
		_skin = SkinSprite.create(sheet)
		_sprite = _skin
	elif creature_id != "" and CreatureSprite.has(creature_id):
		_creature = CreatureSprite.create(creature_id)
		_sprite = _creature
	else:
		_sprite = Sprite2D.new()
		if data.has("aparencia"):
			_sprite.texture = CharacterSprite.make(data.aparencia)
		else:
			_sprite.texture = load(data.sprite)
	_idle_texture = _sprite.texture
	# Quadros de andar opcionais (arte olhando para a direita).
	if not _creature:
		for path in data.get("animacao", {}).get("andar", []):
			_walk_frames.append(load(path))
	var sprite_scale := float(data.get("escala", 1.0))
	_sprite.scale = Vector2.ONE * sprite_scale
	if not _skin and not _creature:
		_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0 + 2)
	if data.has("cor"):
		_sprite.self_modulate = Color.html(data.cor)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(data.get("raio", 6.0 * sprite_scale))
	body_radius = circle.radius
	hit_radius = circle.radius - 5.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	_knockback = _knockback.move_toward(Vector2.ZERO, 500.0 * delta)
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	_show_bar_timer = maxf(_show_bar_timer - delta, 0.0)
	_sprite.modulate = Color(3, 3, 3) if _flash_timer > 0.0 else status.tint(_time)

	var dot := status.update(delta)
	if dot > 0:
		_hurt(dot + GameState.magic_power() / 4)
		if hp <= 0:
			return
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_shoot_cd = maxf(_shoot_cd - delta, 0.0)
	_stun = maxf(_stun - delta, 0.0)
	var move := Vector2.ZERO if _stun > 0.0 else _think(delta) * status.speed_multiplier()
	if _skin:
		# A skin vira sozinha para onde anda; parado, olha para o alvo.
		if move.length() <= 1.0 and is_instance_valid(target):
			_skin.set_direction(target.global_position - global_position)
		if _attack_state == "bote" and _skin.anim != "golpe":
			_skin.play("golpe", true)
	elif _creature:
		if move.length() <= 1.0 and is_instance_valid(target):
			_creature.face(target.global_position - global_position)
		if _attack_state == "bote" and _creature.anim != "ataque":
			_creature.play("ataque", true)
	elif absf(move.x) > 1.0:
		_sprite.flip_h = move.x < 0
	if not _walk_frames.is_empty():
		if move.length() > 1.0:
			var fps := float(data.animacao.get("fps", 8))
			_sprite.texture = _walk_frames[int(_time * fps) % _walk_frames.size()]
		else:
			_sprite.texture = _idle_texture
	if data.get("comportamento", "") == "voar":
		_sprite.position.y = sin(_time * 8.0) * 2.0 - 4.0
	# Aviso do bote: fica vermelho e treme antes de pular.
	if _attack_state == "preparo":
		_sprite.modulate = Color(1.6, 0.6, 0.5)
		_sprite.position.x = sin(_time * 60.0) * 0.8
	else:
		_sprite.position.x = 0.0
	velocity = move + _knockback
	var impact := _knockback.length()
	move_and_slide()
	_physics_impacts(impact)

	_recoil = maxf(_recoil - delta, 0.0)
	if damage > 0 and is_instance_valid(target) and target.global_position.distance_to(global_position) < CONTACT_RADIUS + hit_radius:
		var effect: Dictionary = data.get("efeito", {})
		var hit: bool = target.take_damage(damage, global_position)
		if hit and _skin:
			_skin.play("golpe", true)
		elif hit and _creature:
			_creature.play("ataque", true)
		if hit and not effect.is_empty() and randf() < float(effect.chance):
			target.apply_effect(effect.tipo)
		if _recoil <= 0.0:
			# Bate e volta: quicando para trás, como nos jogos clássicos.
			_recoil = randf_range(0.5, 0.8) if hit else 0.35
			_knockback = (global_position - target.global_position).normalized() * (150.0 if hit else 90.0)
	queue_redraw()


func _think(delta: float) -> Vector2:
	var speed := float(data.velocidade)
	var ai: String = data.get("ia", "voar" if data.get("comportamento", "") == "voar" else "cacador")
	var to_target := Vector2.INF
	if is_instance_valid(target) and target.get("controllable"):
		to_target = target.global_position - global_position
	var dist := to_target.length()
	# Bote em andamento: preparo parado, depois o salto.
	if _attack_state != "":
		return _lunge(delta, to_target, speed)
	if _recoil > 0.0 and to_target != Vector2.INF:
		return (-to_target.normalized() * 0.4 + _separation()) * speed
	# Fera quase morta: as domáveis se encolhem paradas, as outras fogem.
	if data.get("foge", false) and hp <= max_hp * 0.3 and dist < 140.0:
		if Enemy.tame_mount(type_id) != "":
			_sprite.position.x = sin(_time * 40.0) * 0.6
			return _separation() * speed * 0.3
		return (-to_target.normalized() * speed * 1.3 + _separation() * speed)
	if dist < float(data.get("raio_aggro", 90)):
		var dir := to_target.normalized()
		match ai:
			"voar":
				dir = dir.rotated(sin(_time * 4.0) * 0.8)
			"atirador":
				return _ranged(to_target, speed)
			"cacador", "matilha", "tanque":
				# Cerca pelos lados em vez de vir em fila; perto o bastante, prepara o bote.
				var lunge_range := 30.0 + hit_radius
				if dist < lunge_range + 6.0 and _attack_cd <= 0.0 and ai != "tanque" or dist < lunge_range and _attack_cd <= 0.0:
					_attack_state = "preparo"
					_state_timer = 0.38 if ai != "tanque" else 0.55
					return Vector2.ZERO
				if dist > lunge_range:
					var spread := _flank * (1.6 if ai == "matilha" else 1.0)
					var goal := target.global_position - dir.rotated(spread) * minf(dist * 0.6, 26.0)
					dir = (goal - global_position).normalized()
		# Encosta no Ifrit sem entrar nele (o dano de contato já pega nessa distância).
		if dist < CONTACT_RADIUS + hit_radius - 1.0:
			return _separation() * speed
		var rush := 1.4 if ai != "tanque" else 1.1
		return (dir * speed * rush + _separation() * speed).limit_length(speed * rush)
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.0, 3.0)
		_wander = Vector2.ZERO if randf() < 0.4 else Vector2.from_angle(randf() * TAU)
		# Não se afasta demais de onde nasceu.
		if global_position.distance_to(_home) > 80:
			_wander = (_home - global_position).normalized()
	return _wander * speed + _separation() * speed


func _lunge(delta: float, to_target: Vector2, speed: float) -> Vector2:
	_state_timer -= delta
	if _attack_state == "preparo":
		if to_target != Vector2.INF:
			_lunge_dir = to_target.normalized()
		if _state_timer <= 0.0:
			_attack_state = "bote"
			_state_timer = 0.22
		return Vector2.ZERO
	if _state_timer <= 0.0:
		_attack_state = ""
		_attack_cd = randf_range(1.1, 1.8)
		return Vector2.ZERO
	var power := 3.6 if data.get("ia", "") != "tanque" else 2.4
	return _lunge_dir * speed * power


## Atirador: mantém distância, anda de lado e atira de tempos em tempos.
func _ranged(to_target: Vector2, speed: float) -> Vector2:
	var dist := to_target.length()
	var dir := to_target.normalized()
	if _shoot_cd <= 0.0 and dist < 150.0:
		_shoot_cd = randf_range(1.8, 2.6)
		var shot := Projectile.new()
		shot.texture = load(data.get("projetil", "res://assets/flecha.png"))
		shot.direction = dir
		shot.speed = 120.0
		shot.damage = damage
		shot.lifetime = 1.6
		shot.hits_player = true
		var effect: Dictionary = data.get("efeito", {})
		if not effect.is_empty():
			shot.effect = effect.tipo
			shot.effect_chance = float(effect.chance)
		shot.global_position = global_position + dir * 8.0 + Vector2(0, -4)
		get_parent().add_child(shot)
	var strafe := dir.orthogonal() * signf(_flank if _flank != 0.0 else 1.0) * 0.6
	if dist < 55.0:
		return (-dir + strafe + _separation()).normalized() * speed
	if dist > 95.0:
		return (dir + strafe * 0.5 + _separation()).normalized() * speed
	return (strafe + _separation()) * speed * 0.7


## Física dos empurrões: arremessado contra a parede fica tonto; contra outro inimigo, empurra ele também.
func _physics_impacts(impact: float) -> void:
	if impact < 110.0:
		return
	for i in get_slide_collision_count():
		var collider := get_slide_collision(i).get_collider()
		if collider is Enemy and collider != self:
			collider._knockback += _knockback * 0.6
			_knockback *= 0.4
		elif collider is StaticBody2D and _stun <= 0.0:
			_stun = 0.45
			_knockback = Vector2.ZERO
			_flash_timer = 0.08
			_attack_state = ""


## Empurrão para longe de inimigos muito próximos, para não se amontoarem.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("inimigos"):
		if other == self:
			continue
		var away: Vector2 = global_position - other.global_position
		var min_dist: float = body_radius + float(other.body_radius) + 4.0
		var dist := away.length()
		if dist < min_dist:
			push += (away / maxf(dist, 0.01)) * (1.0 - dist / min_dist) if dist > 0.01 else Vector2.from_angle(randf() * TAU)
	return push.limit_length(1.0)


## Montaria que sai desta fera, se ela for domável.
static func tame_mount(enemy_type: String) -> String:
	for id in Data.mounts:
		if Data.mounts[id].get("domar", "") == enemy_type:
			return id
	return ""


func take_damage(amount: int, from: Vector2) -> void:
	if hp <= 0:
		return
	_knockback = (global_position - from).normalized() * 200.0 * float(data.get("recuo", 1.0))
	_hurt(maxi(1, roundi(amount * level_gap_defense())))


func apply_effect(effect: String) -> void:
	if hp > 0:
		status.apply(effect)


## Tira vida sem empurrar (usado também por veneno e queimadura).
func _hurt(amount: int) -> void:
	if hp <= 0:
		return
	hp -= amount
	_flash_timer = 0.1
	_show_bar_timer = 2.0
	if hp > 0:
		Som.sfx("acerto", -4.0, 0.1)
		if _creature:
			_creature.play("dano", true)
	else:
		Som.sfx("quebrar" if data.get("treino", false) else "inimigo_morre", -2.0, 0.1)
	if hp <= 0:
		if _creature and get_parent():
			_creature.spawn_death(get_parent(), position)
		died.emit(self)
		queue_free()


func _draw() -> void:
	if not show_overhead or hp <= 0:
		return
	var near := is_instance_valid(target) and target.global_position.distance_to(global_position) < LABEL_RANGE
	if not near and _show_bar_timer <= 0.0:
		return
	var size := _sprite.texture.get_size()
	if _skin:
		size = Vector2(16, SkinSprite.HEIGHT)
	elif _creature:
		size = Vector2(_creature.info.frame[0] * 0.7, _creature.visible_height())
	var width := maxf(18.0, size.x * _sprite.scale.x * 0.6)
	var top := -size.y * _sprite.scale.y - 4.0
	draw_rect(Rect2(-width / 2 - 1, top - 1, width + 2, 4), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-width / 2, top, width * hp / max_hp, 2), Color(0.9, 0.2, 0.2))
	var close := is_instance_valid(target) and target.global_position.distance_to(global_position) < NAME_RANGE
	if not close and _show_bar_timer <= 0.0:
		return
	var font := ThemeDB.fallback_font
	var title := "%s  Nv %d" % [data.get("nome", ""), int(data.get("nivel", 1))]
	if hp <= max_hp * TAME_HP and Enemy.tame_mount(type_id) != "":
		title += "  (domável)"
	var text_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	var pos := Vector2(-text_w / 2.0, top - 3)
	var color := Color(1, 0.55, 0.45) if int(data.get("nivel", 1)) > GameState.level + 2 else Color(1, 1, 1)
	draw_string_outline(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0, 0, 0, 0.9))
	draw_string(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, color)
