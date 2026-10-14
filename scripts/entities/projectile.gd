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


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | ((1 << 1) if hits_player else (1 << 2))
	var sprite := Sprite2D.new()
	sprite.texture = texture
	if not spin:
		sprite.rotation = direction.angle()
	add_child(sprite)
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
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if hits_player and body.is_in_group("jogador"):
		if body.take_damage(damage, global_position) and effect != "" and randf() < effect_chance:
			body.apply_effect(effect)
	elif not hits_player and body.is_in_group("inimigos"):
		body.take_damage(damage, global_position)
		Som.sfx("fogo_explode", -6.0)
		if effect != "" and is_instance_valid(body) and randf() < effect_chance:
			body.apply_effect(effect)
	queue_free()
