class_name ShakeCamera
extends Camera2D
## Câmera que treme em impactos fortes (golpe especial, chefe derrotado).

var _strength := 0.0
var _time_left := 0.0
var _duration := 0.0


func shake(strength: float, duration: float) -> void:
	if Settings.get_value("tremer_tela") == 0:
		return
	_strength = maxf(_strength, strength)
	_duration = maxf(duration, 0.01)
	_time_left = duration


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		offset = Vector2.ZERO
		return
	_time_left -= delta
	var k := _time_left / _duration
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _strength * k
	if _time_left <= 0.0:
		_strength = 0.0
