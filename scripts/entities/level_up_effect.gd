class_name LevelUpEffect
extends Node2D
## Efeito de subir de nível: anéis dourados, coluna de luz e faíscas subindo em volta do Ifrit.

const DURATION := 1.4

var _time := 0.0
var _sparks: Array = []


func _ready() -> void:
	z_index = 20
	for i in 18:
		_sparks.append({"angle": randf() * TAU, "radius": randf_range(4.0, 12.0),
			"speed": randf_range(18.0, 40.0), "delay": randf() * 0.5})


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _time / DURATION
	var fade := 1.0 - t
	# Coluna de luz.
	var pillar_h := 40.0 * minf(t * 4.0, 1.0)
	draw_rect(Rect2(-6, -pillar_h, 12, pillar_h), Color(1, 0.9, 0.5, 0.35 * fade))
	draw_rect(Rect2(-2, -pillar_h, 4, pillar_h), Color(1, 1, 0.85, 0.6 * fade))
	# Dois anéis que se abrem no chão.
	for k in 2:
		var rt := clampf(t * 1.6 - k * 0.25, 0.0, 1.0)
		if rt > 0.0:
			var r := 4.0 + rt * 22.0
			draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1, 0.8, 0.3, (1.0 - rt) * 0.9), 2.0)
	# Faíscas subindo em espiral.
	for spark in _sparks:
		var st: float = _time - spark.delay
		if st <= 0.0:
			continue
		var a: float = spark.angle + st * 3.0
		var pos := Vector2(cos(a) * spark.radius, -st * spark.speed + sin(a) * 2.0)
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), Color(1, 0.95, 0.6, fade))
