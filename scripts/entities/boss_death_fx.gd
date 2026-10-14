class_name BossDeathFx
extends Node2D
## Morte de chefe: o corpo treme e pisca, pequenas explosões estouram nele,
## depois uma explosão grande com anéis, raios e faíscas, e ele se desfaz em brasas.

signal finished

const CHARGE := 1.3
const BURST := 1.0

var texture: Texture2D
var sprite_scale := 1.0
var flip := false

var _t := 0.0
var _sprite: Sprite2D
var _blasts: Array = []
var _sparks: Array = []
var _next_blast := 0.0
var _burst_done := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 6
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * sprite_scale
	_sprite.flip_h = flip
	if texture:
		_sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 2)
	add_child(_sprite)


func _size() -> float:
	return (texture.get_width() * sprite_scale) if texture else 24.0


func _process(delta: float) -> void:
	_t += delta
	var body := _size()
	if _t < CHARGE:
		# Treme cada vez mais e pisca branco.
		var k := _t / CHARGE
		_sprite.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (1.0 + 3.0 * k)
		_sprite.modulate = Color(3, 3, 3) if int(_t * (10.0 + 20.0 * k)) % 2 == 0 else Color(1, 0.6, 0.5)
		_next_blast -= delta
		if _next_blast <= 0.0:
			_next_blast = lerpf(0.18, 0.06, k)
			_blasts.append({"p": Vector2(randf_range(-0.5, 0.5) * body, -randf() * body * 0.9), "t": 0.0, "r": randf_range(5, 9)})
	elif not _burst_done:
		_burst_done = true
		_sprite.modulate = Color(4, 4, 4)
		for i in 48:
			var ang := randf() * TAU
			_sparks.append({"v": Vector2.from_angle(ang) * randf_range(60, 190), "p": Vector2(0, -body * 0.4), "s": randf_range(1.0, 3.0)})
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"):
			cam.shake(7.0, 0.7)
	else:
		var k := (_t - CHARGE) / BURST
		_sprite.scale = Vector2.ONE * sprite_scale * (1.0 + k * 0.6)
		_sprite.modulate = Color(1, 0.7, 0.4, maxf(0.0, 1.0 - k * 2.0))
		for s in _sparks:
			s.p += s.v * delta
			s.v *= 0.95
			s.v.y += 40.0 * delta
		if k >= 1.0:
			finished.emit()
			queue_free()
	for b in _blasts:
		b.t += delta
	_blasts = _blasts.filter(func(b): return b.t < 0.35)
	queue_redraw()


func _draw() -> void:
	var body := _size()
	for b in _blasts:
		var k: float = b.t / 0.35
		draw_circle(b.p, b.r * (0.4 + k), Color(1, 0.6 + 0.3 * (1 - k), 0.2, 1.0 - k))
		draw_arc(b.p, b.r * (0.6 + k * 1.4), 0, TAU, 16, Color(1, 1, 0.8, 1.0 - k), 1.5)
	if _burst_done:
		var k := clampf((_t - CHARGE) / BURST, 0.0, 1.0)
		var c := Vector2(0, -body * 0.4)
		# Raios de luz.
		for i in 12:
			var a := TAU * i / 12.0 + _t
			var tip := c + Vector2.from_angle(a) * (40.0 + 140.0 * k)
			var side := Vector2.from_angle(a + PI / 2) * 5.0 * (1.0 - k)
			draw_colored_polygon(PackedVector2Array([c + side, c - side, tip]), Color(1, 0.85, 0.4, 0.5 * (1.0 - k)))
		# Anéis de choque.
		for i in 3:
			var kk := clampf(k * 1.4 - i * 0.18, 0.0, 1.0)
			if kk > 0.0:
				draw_arc(c, 10.0 + 120.0 * kk, 0, TAU, 48, Color(1, 0.5 + 0.4 * i / 2.0, 0.2, 1.0 - kk), 4.0 - i)
		draw_circle(c, 30.0 * (1.0 - k), Color(1, 1, 0.85, 1.0 - k))
		for s in _sparks:
			draw_circle(s.p, s.s * (1.0 - k * 0.7), Color(1, 0.75 - 0.4 * k, 0.2, 1.0 - k * 0.8))
