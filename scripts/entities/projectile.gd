class_name Projectile
extends Area2D
## Projétil genérico: bola de fogo, flecha ou cuspe de chefe.

var texture: Texture2D
var direction := Vector2.RIGHT
var speed := 160.0
var damage := 1
var lifetime := 1.2
var hits_player := false
var spin := false
## Efeito de status aplicado em quem for atingido ("" = nenhum).
var effect := ""
var effect_chance := 1.0
## Bola de fogo do Ifrit: rastro de chamas, clarão ao sair e explosão ao acertar.
var fiery := false

var _trail: CPUParticles2D
var _anim_sprite: Sprite2D
var _anim_time := 0.0

const FX_DIR := "res://assets/efeitos/"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | ((1 << 1) if hits_player else (1 << 2))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	if not spin:
		sprite.rotation = direction.angle()
	add_child(sprite)
	if fiery:
		_add_fire_fx(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if spin:
		rotation += delta * 10.0
	if _anim_sprite:
		_anim_time += delta
		_anim_sprite.frame = int(_anim_time * 12.0) % 6
	lifetime -= delta
	if lifetime <= 0.0:
		if fiery:
			_explode(0.6)
		queue_free()


func _on_body_entered(body: Node) -> void:
	if fiery:
		_explode(1.0)
	if hits_player and body.is_in_group("jogador"):
		if body.take_damage(damage, global_position) and effect != "" and randf() < effect_chance:
			body.apply_effect(effect)
	elif not hits_player and body.is_in_group("inimigos"):
		body.take_damage(damage, global_position)
		if not fiery:
			Som.sfx("fogo_explode", -6.0)
		if effect != "" and is_instance_valid(body) and randf() < effect_chance:
			body.apply_effect(effect)
	queue_free()


func _add_fire_fx(sprite: Sprite2D) -> void:
	# Bola de fogo desenhada (fio de Artes): 6 quadros em loop, núcleo em (16,12), olhando para a direita.
	if ResourceLoader.exists(FX_DIR + "bola_fogo_voo.png"):
		sprite.texture = load(FX_DIR + "bola_fogo_voo.png")
		sprite.hframes = 6
		sprite.offset = Vector2(12, 12) - Vector2(16, 12)
		sprite.rotation = direction.angle()
		_anim_sprite = sprite
		play_once(get_parent(), "bola_fogo_disparo.png", 4, 16.0, global_position)
	# Brilho em volta e rastro de fagulhas que ficam para trás.
	var glow := Sprite2D.new()
	glow.texture = _glow_texture()
	glow.modulate = Color(1.0, 0.55, 0.15, 0.55)
	glow.material = _additive()
	glow.scale = Vector2.ONE * 0.9
	add_child(glow)
	move_child(glow, 0)
	_trail = CPUParticles2D.new()
	_trail.local_coords = false
	_trail.amount = 24
	_trail.lifetime = 0.35
	_trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_trail.emission_sphere_radius = 2.5
	_trail.direction = -direction
	_trail.spread = 25.0
	_trail.initial_velocity_min = 10.0
	_trail.initial_velocity_max = 30.0
	_trail.gravity = Vector2(0, -20)
	_trail.scale_amount_min = 1.0
	_trail.scale_amount_max = 2.5
	_trail.color_ramp = _fire_ramp()
	_trail.material = _additive()
	add_child(_trail)
	move_child(_trail, 0)
	# Clarão na mão do Ifrit ao lançar.
	_burst(get_parent(), global_position, 10, 0.25, 40.0, 0.7)


## Explosão no acerto: clarão, labaredas para todos os lados e fumaça.
func _explode(power: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	_burst(parent, global_position, int(22 * power), 0.45, 70.0 * power, power)
	if power >= 1.0:
		play_once(parent, "bola_fogo_explosao.png", 6, 14.0, global_position)
	Som.sfx("fogo_explode", -6.0 if power >= 1.0 else -10.0)
	var flash := Sprite2D.new()
	flash.texture = _glow_texture()
	flash.material = _additive()
	flash.modulate = Color(1.0, 0.8, 0.4, 0.9)
	flash.global_position = global_position
	flash.scale = Vector2.ONE * 0.6
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.set_parallel()
	tween.tween_property(flash, "scale", Vector2.ONE * 1.8 * power, 0.25)
	tween.tween_property(flash, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(flash.queue_free)
	# O rastro continua um pouco no lugar antes de sumir.
	if _trail and is_instance_valid(_trail):
		_trail.emitting = false
		var pos := _trail.global_position
		remove_child(_trail)
		parent.add_child(_trail)
		_trail.global_position = pos
		parent.get_tree().create_timer(0.5, false).timeout.connect(_trail.queue_free)
		_trail = null


## Toca uma folha de efeito (uma linha de quadros) uma vez no ponto e some.
static func play_once(parent: Node, file: String, frames: int, fps: float, at: Vector2) -> void:
	if parent == null or not ResourceLoader.exists(FX_DIR + file):
		return
	var fx := Sprite2D.new()
	fx.texture = load(FX_DIR + file)
	fx.hframes = frames
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.global_position = at
	fx.z_index = 2
	parent.add_child(fx)
	var tween := fx.create_tween()
	tween.tween_property(fx, "frame", frames - 1, frames / fps).from(0)
	tween.tween_callback(fx.queue_free)


static func _burst(parent: Node, at: Vector2, amount: int, life: float, speed: float, size: float) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(amount, 4)
	p.lifetime = life
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.3
	p.initial_velocity_max = speed
	p.damping_min = speed * 1.5
	p.damping_max = speed * 2.5
	p.gravity = Vector2(0, -30)
	p.scale_amount_min = 1.0 * size
	p.scale_amount_max = 3.0 * size
	p.color_ramp = _fire_ramp()
	p.material = _additive()
	p.global_position = at
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(life + 0.2, false).timeout.connect(p.queue_free)


static func _fire_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 0.75, 1), Color(1, 0.7, 0.2, 0.95), Color(0.9, 0.25, 0.05, 0.7), Color(0.25, 0.1, 0.1, 0.0)])
	return g


static var _glow: Texture2D
static var _add_mat: CanvasItemMaterial


static func _glow_texture() -> Texture2D:
	if _glow == null:
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		g.width = 24
		g.height = 24
		var grad := Gradient.new()
		grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		g.gradient = grad
		_glow = g
	return _glow


static func _additive() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat
