class_name Boss
extends Enemy
## Chefe em três fases (acima de 66%, até 33% e furioso). Cada fase ataca mais rápido e
## libera ataques novos. Todo ataque perigoso tem um aviso antes, para dar tempo de reagir.

signal hp_changed(hp: int, max_hp: int)
signal summon(type_id: String, at: Vector2)

const PHASE_SPEED := [1.0, 1.25, 1.5]
const PHASE_DELAY := [1.0, 0.7, 0.5]

var phase := 0
var _pattern_timer := 2.5
var _windup := 0.0
var _dash_timer := 0.0
var _dashes_left := 0
var _dash_dir := Vector2.ZERO
var _shield_timer := 0.0
var _spiral_left := 0
var _spiral_timer := 0.0
var _spiral_angle := 0.0
var _invulnerable := 0.0


## Dificuldade: chefes com ~40% mais vida.
func hp_mult() -> float:
	return 1.6


func _ready() -> void:
	super._ready()
	show_overhead = false
	add_to_group("chefes")


func _patterns() -> Array:
	var list: Array = data.padroes.duplicate()
	if phase >= 1:
		list += ["espiral", "onda"]
	if phase >= 2:
		list += ["investida", "onda"]
	return list


func _think(delta: float) -> Vector2:
	_shield_timer = maxf(_shield_timer - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	queue_redraw()
	if not is_instance_valid(target) or not target.get("controllable"):
		return Vector2.ZERO
	var to_target := target.global_position - global_position
	_update_spiral(delta)
	# Preparando a investida: para e pisca, mirando no Ifrit.
	if _windup > 0.0:
		_windup -= delta
		_dash_dir = to_target.normalized()
		if _windup <= 0.0:
			_dash_timer = 0.4
		queue_redraw()
		return Vector2.ZERO
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if _dash_timer <= 0.0 and _dashes_left > 0:
			_dashes_left -= 1
			_windup = 0.25
		return _dash_dir * float(data.velocidade) * 4.5
	_pattern_timer -= delta
	if _pattern_timer <= 0.0:
		# Cada chefe vencido antes deixa os próximos mais agressivos.
		_pattern_timer = randf_range(2.0, 3.2) * PHASE_DELAY[phase] * maxf(0.7, 1.0 - 0.05 * GameState.boss_tier())
		_use_pattern(_patterns().pick_random(), to_target)
	var speed: float = float(data.velocidade) * PHASE_SPEED[phase]
	# Depois de encostar no Ifrit, recua (bate e volta) em vez de ficar colado.
	if _recoil > 0.0:
		return -to_target.normalized() * speed * 1.4
	# De perto, rodeia o Ifrit a uma distância segura; o contato fica para as investidas.
	var keep := hit_radius + 30.0
	if to_target.length() < keep:
		var side := 1.0 if int(_time / 2.5) % 2 == 0 else -1.0
		return (to_target.normalized().orthogonal() * side - to_target.normalized() * 0.8).normalized() * speed
	return to_target.normalized() * speed


func _use_pattern(pattern: String, to_target: Vector2) -> void:
	if _creature:
		_creature.play("especial" if _creature.has_anim("especial") else "ataque", true)
	match pattern:
		"investida":
			_windup = 0.45
			_dashes_left = phase
		"invocar":
			# Limita a quantidade de lacaios vivos.
			var nearby := get_tree().get_nodes_in_group("inimigos").filter(
				func(e): return e != self and e.global_position.distance_to(global_position) < 140.0)
			if nearby.size() >= 4 or not data.has("invoca"):
				_use_pattern("projeteis", to_target)
				return
			for i in 2 + phase:
				summon.emit(data.invoca, global_position + Vector2.from_angle(randf() * TAU) * 28.0)
			# Enquanto os lacaios chegam, o chefe fica protegido (só leva 1/4 do dano).
			_shield_timer = 4.0
		"projeteis":
			_ring(8 + phase * 4, 90.0 + phase * 20.0, _time)
			if phase == 2:
				get_tree().create_timer(0.3, false).timeout.connect(func():
					if is_instance_valid(self):
						_ring(16, 120.0, _time + PI / 16.0))
		"espiral":
			_spiral_left = 18 + phase * 6
			_spiral_timer = 0.0
			_spiral_angle = to_target.angle()
		"onda":
			Som.sfx("chefe_impacto", -3.0, 0.05)
			var wave := Shockwave.new()
			wave.target = target
			wave.damage = damage
			wave.max_radius = 120.0 + phase * 30.0
			# Fases avançadas: brechas mais estreitas.
			wave.gap_width = 0.75 - 0.12 * phase
			wave.gaps = 3 if phase < 2 else 2
			wave.global_position = global_position
			get_parent().add_child(wave)


func _ring(count: int, speed: float, offset: float) -> void:
	for i in count:
		_shoot(Vector2.from_angle(TAU * i / count + offset), speed)


func _update_spiral(delta: float) -> void:
	if _spiral_left <= 0:
		return
	_spiral_timer -= delta
	if _spiral_timer <= 0.0:
		_spiral_timer = 0.07
		_spiral_left -= 1
		_spiral_angle += 0.45
		_shoot(Vector2.from_angle(_spiral_angle), 100.0)
		_shoot(Vector2.from_angle(_spiral_angle + PI), 100.0)


func _shoot(direction: Vector2, speed: float) -> void:
	var shot := Projectile.new()
	shot.texture = load(data.get("projetil", "res://assets/bola_de_fogo.png"))
	shot.direction = direction
	shot.speed = speed
	shot.damage = damage
	shot.lifetime = 2.2
	shot.hits_player = true
	var effect: Dictionary = data.get("efeito", {})
	if not effect.is_empty():
		shot.effect = effect.tipo
		shot.effect_chance = float(effect.chance)
	shot.spin = true
	shot.global_position = global_position + Vector2(0, -8)
	get_parent().add_child(shot)


func _hurt(amount: int) -> void:
	if _invulnerable > 0.0:
		return
	if _shield_timer > 0.0:
		amount = maxi(1, amount / 4)
		Som.sfx("acerto_metal", -6.0)
	super._hurt(amount)
	var new_phase := 2 if hp <= max_hp / 3 else 1 if hp <= max_hp * 2 / 3 else 0
	if hp > 0 and new_phase > phase:
		phase = new_phase
		# Troca de fase: um instante invulnerável, onda de choque e cor mais forte.
		_invulnerable = 1.0
		Som.sfx("chefe_fase")
		_sprite.self_modulate = Color(1.3, 0.75, 0.75) if phase == 1 else Color(1.5, 0.5, 0.5)
		_use_pattern("onda", Vector2.ZERO)
		GameState.toast.emit("%s ficou %s!" % [data.nome, "furioso" if phase == 1 else "enlouquecido"])
	hp_changed.emit(maxi(hp, 0), max_hp)


func _draw() -> void:
	if _windup > 0.0:
		var blink := 0.4 + 0.4 * sin(_time * 40.0)
		draw_line(Vector2.ZERO, _dash_dir * 90.0, Color(1, 0.2, 0.1, blink), 3.0)
	if _shield_timer > 0.0:
		draw_arc(Vector2(0, -8), 20.0, 0, TAU, 32, Color(0.4, 0.7, 1.0, 0.7), 2.0)
