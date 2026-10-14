class_name Shockwave
extends Node2D
## Onda de choque de chefe: primeiro um aviso no chão, depois um anel que cresce.
## O anel tem brechas: quem estiver numa brecha (ou longe demais) não leva dano.

var target: Node2D
var damage := 1
var max_radius := 140.0
var warn_time := 0.6
var grow_time := 0.9
var color := Color(1, 0.45, 0.2)
## Quantas brechas e a largura de cada uma (em radianos).
var gaps := 3
var gap_width := 0.6

var _t := 0.0
var _radius := 0.0
var _hit := false
var _gap_start := 0.0


func _ready() -> void:
	_gap_start = randf() * TAU


func _in_gap(angle: float) -> bool:
	for i in gaps:
		var center := _gap_start + TAU * i / gaps
		if absf(angle_difference(angle, center)) < gap_width / 2.0:
			return true
	return false


func _process(delta: float) -> void:
	_t += delta
	if _t > warn_time:
		_radius = max_radius * clampf((_t - warn_time) / grow_time, 0.0, 1.0)
		if not _hit and is_instance_valid(target):
			var to_target := target.global_position - global_position
			if absf(to_target.length() - _radius) < 7.0 and not _in_gap(to_target.angle()):
				_hit = target.take_damage(damage, global_position)
	if _t > warn_time + grow_time:
		queue_free()
	queue_redraw()


## Desenha o anel pulando as brechas.
func _ring(r: float, col: Color, width: float) -> void:
	for i in gaps:
		var from := _gap_start + TAU * i / gaps + gap_width / 2.0
		var to := _gap_start + TAU * (i + 1) / gaps - gap_width / 2.0
		draw_arc(Vector2.ZERO, r, from, to, 24, col, width)


func _draw() -> void:
	if _t <= warn_time:
		var blink := 0.35 + 0.35 * sin(_t * 30.0)
		_ring(max_radius, Color(color, blink * 0.5), 1.0)
		draw_circle(Vector2.ZERO, 10.0 + _t * 20.0, Color(color, blink))
		# Brechas seguras marcadas em verde claro.
		for i in gaps:
			var a := _gap_start + TAU * i / gaps
			draw_line(Vector2.from_angle(a) * 18.0, Vector2.from_angle(a) * max_radius, Color(0.6, 1.0, 0.6, 0.35), 2.0)
	else:
		_ring(_radius, Color(color, 0.9), 5.0)
		_ring(_radius, Color(1, 1, 0.8, 0.9), 2.0)
