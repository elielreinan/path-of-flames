class_name Player
extends CharacterBody2D
## Ifrit, o herói controlado pelo jogador. Vida, nível e arma ficam no GameState.

signal died
signal interact_requested

const LOOK := {"cabelo": "curto", "corpo": "tunica", "cores": {
	"h": "#c82820", "y": "#f0be3c", "b": "#285aaa", "a": "#f0be3c", "d": "#5a3c28"}}
const SPEED := 80.0
const ATTACK_RANGE := 24.0
const ATTACK_COOLDOWN := 0.35
const FIREBALL_COOLDOWN := 0.8
const INVULNERABLE_TIME := 1.0
## Física do andar: acelera e freia em vez de parar seco. A areia fofa escorrega mais.
const ACCEL := 900.0
const FRICTION := 1100.0
## Golpe especial (Fúria das Brasas): raio, duração da invulnerabilidade e multiplicador de dano.
const SPECIAL_RADIUS := 64.0
const SPECIAL_TIME := 0.6
const SPECIAL_POWER := 3.0
## Montaria: quanto mais rápido que a pé.
const MOUNT_SPEED := 1.85

var facing := Vector2.DOWN
var joystick: TouchJoystick
var controllable := true
## Verdadeiro enquanto o Ifrit está na água: anda devagar e não ataca.
var swimming := false

var _attack_timer := 0.0
var _fireball_timer := 0.0
var _invulnerable_timer := 0.0
var _slash_timer := 0.0
var _knockback := Vector2.ZERO
var _special_timer := 0.0
var _ghost_timer := 0.0
var _move := Vector2.ZERO
## Montado: anda bem mais rápido, mas não ataca. Leva um golpe e cai.
var mounted := false
var _mount_sprite: Sprite2D
var status := StatusEffects.new()
var _regen_timer := 0.0
var _sprite: IfritRig
var _hurt_timer := 0.0
var _time := 0.0
var _step_timer := 0.0


func _ready() -> void:
	add_to_group("jogador")
	GameState.status_cured.connect(func(): status.clear())
	collision_layer = 1 << 1
	collision_mask = 1
	_sprite = IfritRig.new()
	_mount_sprite = Sprite2D.new()
	_mount_sprite.visible = false
	add_child(_mount_sprite)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)


func _physics_process(delta: float) -> void:
	_time += delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_fireball_timer = maxf(_fireball_timer - delta, 0.0)
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
	_slash_timer = maxf(_slash_timer - delta, 0.0)
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)

	# Veneno e queimadura tiram vida aos poucos, mas nunca derrubam o Ifrit sozinhos.
	# Clérigo: recupera 1 de vida a cada poucos segundos.
	var regen := GameState.class_bonus("regen", 0.0)
	if regen > 0.0 and GameState.hp > 0 and GameState.hp < GameState.max_hp():
		_regen_timer += delta
		if _regen_timer >= regen:
			_regen_timer = 0.0
			GameState.heal(1)
	var dot := status.update(delta)
	if dot > 0 and GameState.hp > 1:
		GameState.take_damage(mini(dot, GameState.hp - 1))
	var ground := _ground()
	_set_swimming(ground == TileLayer.WATER)
	if swimming and mounted:
		set_mounted(false)
		GameState.toast.emit("A montaria não entra na água.")
	var input := Vector2.ZERO
	if controllable:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if joystick:
			input += joystick.output
		input = input.limit_length(1.0)
		if input.length() > 0.2:
			face(input)
		if Input.is_action_just_pressed("attack"):
			attack()
		if Input.is_action_just_pressed("fireball"):
			shoot_fireball()
		if Input.is_action_just_pressed("especial"):
			special()
		if Input.is_action_just_pressed("montar"):
			toggle_mount()
		if Input.is_action_just_pressed("item_rapido"):
			use_quick_item()
		if Input.is_action_just_pressed("interact"):
			interact_requested.emit()

	_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
	if _special_timer > 0.0:
		_special_timer -= delta
		input = Vector2.ZERO
		_sprite.rotation = TAU * (1.0 - _special_timer / SPECIAL_TIME) * 2.0
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = 0.05
			_spawn_ghost()
		if _special_timer <= 0.0:
			_sprite.rotation = 0.0
	var top_speed := SPEED * float(TileLayer.SPEED.get(ground, 1.0)) * status.speed_multiplier()
	if mounted:
		# A montaria não sente a areia fofa.
		top_speed = SPEED * MOUNT_SPEED * maxf(1.0, float(TileLayer.SPEED.get(ground, 1.0)))
	var grip := 0.6 if ground == "." else 1.0
	if input.length() > 0.05:
		_move = _move.move_toward(input * top_speed, ACCEL * grip * delta)
	else:
		_move = _move.move_toward(Vector2.ZERO, FRICTION * grip * delta)
	velocity = _move + _knockback
	move_and_slide()
	# Bateu na parede: perde o embalo naquela direção.
	if get_slide_collision_count() > 0:
		_move = velocity - _knockback

	# Montado, o Ifrit balança junto com a montaria; a pé, a animação já faz o passo.
	if mounted:
		if _mount_sprite is CreatureSprite:
			# A folha da montaria já anima o passo; o Ifrit senta na sela e acompanha.
			var ride := _mount_sprite as CreatureSprite
			ride.move_anim = "correr" if velocity.length() > SPEED * 1.25 else "andar"
			if ride.directional():
				ride.face(facing)
			else:
				ride.flip_h = facing.x < -0.1 or (absf(facing.x) <= 0.1 and ride.flip_h)
			var seat := ride.saddle()
			_sprite.position = Vector2(seat.x, seat.y + 6.0 + (1.0 if ride.anim != "parado" and ride.anim_frame % 2 == 1 else 0.0))
		else:
			var gallop := absf(sin(_time * 16.0)) if velocity.length() > 5.0 else 0.0
			_mount_sprite.position.y = -gallop
			_sprite.position.y = _mount_sprite.position.y - 7.0 - gallop * 0.5
	else:
		_sprite.position = Vector2.ZERO
	_update_animation()
	_footsteps(delta)
	_sprite.visible = _invulnerable_timer <= 0.0 or _hurt_timer > 0.0 or int(_time * 20.0) % 2 == 0
	_sprite.tint = status.tint(_time)
	queue_redraw()


## Escolhe a animação das camadas do Ifrit conforme o que ele está fazendo.
func _update_animation() -> void:
	if GameState.hp <= 0:
		_sprite.play("morrer")
	elif _special_timer > 0.0:
		_sprite.play("golpe")
	elif _hurt_timer > 0.0:
		_sprite.play("dano")
	elif _sprite.anim == "golpe" and not _sprite.done:
		pass
	elif swimming:
		_sprite.play("nadar")
	elif mounted:
		_sprite.play("parado")
	elif velocity.length() > 5.0:
		_sprite.play("correr" if velocity.length() > SPEED * 1.25 else "andar")
	else:
		_sprite.play("parado")


func face(direction: Vector2) -> void:
	facing = direction.normalized()
	_sprite.set_direction(facing)
	if _mount_sprite is CreatureSprite and (_mount_sprite as CreatureSprite).directional():
		(_mount_sprite as CreatureSprite).face(facing)
	elif absf(facing.x) > 0.1:
		if _mount_sprite is CreatureSprite:
			_mount_sprite.flip_h = facing.x < 0
		else:
			_mount_sprite.flip_h = (facing.x < 0) != bool(Data.mount(GameState.mount).get("olha_esquerda", false))


func _ground() -> String:
	var tiles := get_tree().get_first_node_in_group("terreno") as TileLayer
	return tiles.terrain_at(global_position) if tiles else "."


func _set_swimming(value: bool) -> void:
	if value == swimming:
		return
	swimming = value


## Fração (0 a 1) do tempo de recarga que falta, para os botões mostrarem.
func cooldown_fraction(action: String) -> float:
	match action:
		"attack": return _attack_timer / ATTACK_COOLDOWN
		"fireball": return _fireball_timer / (FIREBALL_COOLDOWN * GameState.class_bonus("fogo", 1.0))
		"especial": return 1.0 - GameState.fury / GameState.FURY_MAX
	return 0.0


## Passos na areia (mais rápidos montado) e braçadas na água.
func _footsteps(delta: float) -> void:
	var speed := velocity.length()
	if speed < 12.0 or not controllable:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer > 0.0:
		return
	if swimming:
		_step_timer = 0.6
		Som.sfx("nadar", -10.0)
	else:
		_step_timer = clampf(14.0 / speed, 0.16, 0.4)
		Som.sfx("passo", -15.0 if mounted else -17.0, 0.12)


## Fúria das Brasas: com a barra cheia, o Ifrit gira em chamas e queima tudo em volta.
func special() -> void:
	if not GameState.has_flag("golpe_especial"):
		GameState.toast.emit("Você ainda não aprendeu o golpe especial.")
		return
	if GameState.fury < GameState.FURY_MAX:
		GameState.toast.emit("A Fúria ainda não está cheia. Acerte inimigos para encher.")
		return
	if swimming:
		return
	if mounted:
		set_mounted(false)
	GameState.fury = 0.0
	GameState.changed.emit()
	_special_timer = SPECIAL_TIME
	Som.sfx("furia")
	_invulnerable_timer = maxf(_invulnerable_timer, SPECIAL_TIME + 0.2)
	var nova := FireNova.new()
	nova.radius = SPECIAL_RADIUS
	nova.damage = int(GameState.attack_power() * SPECIAL_POWER + GameState.magic_power())
	nova.global_position = global_position
	get_parent().add_child(nova)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(4.0, 0.4)


## Sobe e desce da montaria. Só dá fora de casas e cavernas, e longe da água.
func toggle_mount() -> void:
	if mounted:
		set_mounted(false)
		return
	if GameState.mount == "":
		GameState.toast.emit("Você ainda não tem montaria.")
		return
	var world := get_tree().get_first_node_in_group("mundo")
	if world and not world.mount_allowed():
		GameState.toast.emit("Não dá para montar aqui dentro.")
		return
	if swimming:
		return
	set_mounted(true)


func set_mounted(value: bool, announce := true) -> void:
	if value == mounted:
		return
	mounted = value
	GameState.riding = value
	if value and announce:
		Som.sfx("montar", -4.0)
	_mount_sprite.visible = value
	if value:
		var info := Data.mount(GameState.mount)
		_set_mount_node(CreatureSprite.create(info.criatura) if CreatureSprite.has(info.get("criatura", "")) else Sprite2D.new())
		if _mount_sprite is CreatureSprite:
			var ride := _mount_sprite as CreatureSprite
			if ride.directional():
				ride.face(facing)
			else:
				ride.flip_h = facing.x < 0
		else:
			_mount_sprite.texture = load(info.sprite)
			_mount_sprite.offset = Vector2(0, -_mount_sprite.texture.get_height() / 2.0 + 3)
			_mount_sprite.flip_h = (facing.x < 0) != bool(info.get("olha_esquerda", false))
		if announce:
			GameState.toast.emit("Montado: %s" % info.nome)
	else:
		_sprite.position = Vector2.ZERO
	if not value:
		_mount_sprite.position.y = 0.0
		if _mount_sprite is CreatureSprite and (_mount_sprite as CreatureSprite).front:
			(_mount_sprite as CreatureSprite).front.visible = false


## Troca o nó da montaria (folha animada nova ou sprite antigo), mantendo-o atrás do Ifrit.
func _set_mount_node(node: Sprite2D) -> void:
	var index := _mount_sprite.get_index()
	if _mount_sprite is CreatureSprite and (_mount_sprite as CreatureSprite).front:
		(_mount_sprite as CreatureSprite).front.queue_free()
	_mount_sprite.queue_free()
	_mount_sprite = node
	add_child(node)
	move_child(node, index)
	# Cabeça da montaria de frente fica por cima do Ifrit.
	if node is CreatureSprite and (node as CreatureSprite).front:
		add_child((node as CreatureSprite).front)
		move_child((node as CreatureSprite).front, _sprite.get_index() + 1)


func _spawn_ghost() -> void:
	var ghost := _sprite.snapshot()
	ghost.global_position = _sprite.global_position
	ghost.rotation = _sprite.rotation
	ghost.modulate = Color(1.0, 0.6, 0.3, 0.6)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


func use_quick_item() -> void:
	var id := GameState.quick_item
	if id == "" or GameState.item_count(id) == 0:
		GameState.toast.emit("Nenhum item no atalho." if id == "" else "Acabou: %s." % Data.item(id).nome)
		return
	GameState.toast.emit(GameState.use_item(id))


func attack() -> void:
	if _attack_timer > 0.0 or swimming or _special_timer > 0.0:
		return
	if mounted:
		set_mounted(false)
	_attack_timer = ATTACK_COOLDOWN
	_slash_timer = 0.15
	_sprite.play("golpe", true)
	Som.sfx("espada", -3.0, 0.1)
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		var reach: float = ATTACK_RANGE + float(enemy.hit_radius)
		if to_enemy.length() < reach and facing.dot(to_enemy.normalized()) > 0.2:
			enemy.take_damage(GameState.attack_power(), global_position)
			GameState.add_fury(GameState.FURY_PER_HIT)


func shoot_fireball() -> void:
	if _fireball_timer > 0.0 or swimming or mounted or not GameState.has_flag("magia_fogo"):
		return
	_fireball_timer = FIREBALL_COOLDOWN * GameState.class_bonus("fogo", 1.0)
	var fireball := Projectile.new()
	fireball.texture = preload("res://assets/bola_de_fogo.png")
	fireball.direction = facing
	fireball.damage = GameState.magic_power()
	fireball.spin = true
	fireball.effect = "queimadura"
	fireball.fiery = true
	Som.sfx("fogo", -3.0)
	fireball.global_position = global_position + facing * 8.0 + Vector2(0, -4)
	get_parent().add_child(fireball)


## Devolve verdadeiro se o golpe pegou (para o inimigo aplicar veneno, etc.).
func take_damage(amount: int, from: Vector2) -> bool:
	if _invulnerable_timer > 0.0 or _special_timer > 0.0 or GameState.hp <= 0 or not controllable:
		return false
	# Golpe forte derruba da montaria.
	if mounted:
		set_mounted(false)
		GameState.toast.emit("Você caiu da montaria!")
	# A armadura reduz o dano de golpes (nunca abaixo de 1).
	GameState.take_damage(maxi(1, amount - GameState.defense()))
	_invulnerable_timer = INVULNERABLE_TIME
	_hurt_timer = 0.35
	_sprite.play("dano", true)
	Som.sfx("dano")
	_knockback = (global_position - from).normalized() * 180.0
	if GameState.hp == 0:
		controllable = false
		_sprite.play("morrer", true)
		status.clear()
		died.emit()
	return true


func apply_effect(effect: String) -> void:
	if GameState.CLASSES.get(GameState.classe, {}).get("imune", "") == effect:
		return
	if GameState.hp > 0:
		var had := status.active.has(effect)
		status.apply(effect)
		if not had:
			GameState.toast.emit("%s!" % StatusEffects.INFO[effect].nome)


func _draw() -> void:
	# Ondinhas em volta quando está nadando.
	if swimming:
		var wave := 0.5 + 0.5 * sin(_time * 5.0)
		draw_arc(Vector2(0, 0), 7.0 + wave * 2.0, PI, TAU, 12, Color(1, 1, 1, 0.6 - wave * 0.3), 1.0)
		draw_arc(Vector2(0, 1), 10.0 + wave * 3.0, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.35 - wave * 0.2), 1.0)
	# Golpe de espada em arco na direção em que o Ifrit está olhando.
	if _slash_timer > 0.0 and GameState.weapon == "":
		var angle := facing.angle()
		draw_arc(Vector2(0, -4), 16.0, angle - 1.1, angle + 1.1, 10, Color(1.0, 1.0, 0.9, _slash_timer / 0.15), 3.0)
