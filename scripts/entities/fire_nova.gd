class_name FireNova
extends Node2D
## Fúria das Brasas: anel de fogo que cresce em volta do Ifrit e acerta cada inimigo uma vez,
## empurrando para longe e deixando queimadura. Faíscas voam para fora.

var radius := 64.0
var damage := 10
var duration := 0.45

var _t := 0.0
var _hit := {}
var _sparks: Array = []


func _ready() -> void:
	z_index = 5
	for i in 28:
		var ang := TAU * i / 28.0 + randf() * 0.2
		_sparks.append({"dir": Vector2.from_angle(ang), "speed": randf_range(70, 150), "size": randf_range(1.0, 2.5)})


func _process(delta: float) -> void:
	_t += delta
	var r := radius * clampf(_t / duration, 0.0, 1.0)
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		if _hit.has(enemy) or not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_to(global_position) <= r + float(enemy.hit_radius):
			_hit[enemy] = true
			enemy.take_damage(damage, global_position)
			enemy.apply_effect("queimadura")
	if _t > duration + 0.35:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var r := radius * k
	var fade := 1.0 - clampf((_t - duration) / 0.35, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.45, 0.1, 0.18 * fade))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1.0, 0.5, 0.15, 0.9 * fade), 6.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1.0, 0.95, 0.6, fade), 2.0)
	draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 40, Color(1.0, 0.3, 0.1, 0.5 * fade), 2.0)
	for s in _sparks:
		var p: Vector2 = s.dir * s.speed * _t
		draw_circle(p, s.size * fade, Color(1.0, 0.8 - 0.4 * k, 0.2, fade))
