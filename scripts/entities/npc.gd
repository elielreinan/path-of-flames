class_name Npc
extends CharacterBody2D
## Personagem com quem o Ifrit conversa. Dados em npcs.json; diálogo escolhido pela primeira "fala" cuja condição vale.

var npc_id := ""
var data := {}
var wander := false

var _home := Vector2.ZERO
var _wander_timer := 0.0
var _wander_dir := Vector2.ZERO
var _sprite: Sprite2D
## Skin Sunnyside (null quando o NPC usa sprite próprio ou a arte antiga).
var _skin: SkinSprite
var _marker: Label
var _name_label: Label
var _time := 0.0


func _ready() -> void:
	add_to_group("npcs")
	collision_layer = 1
	# NPCs também nadam: a água não bloqueia mais quem passeia.
	collision_mask = 1
	_home = position
	var sheet: Texture2D = null if data.has("sprite") else SkinSprite.sheet_for("npcs", npc_id)
	if sheet:
		_skin = SkinSprite.create(sheet)
		_sprite = _skin
	else:
		_sprite = Sprite2D.new()
		if data.has("sprite"):
			_sprite.texture = load(data.sprite)
		else:
			_sprite.texture = CharacterSprite.make(data.get("aparencia", {}))
		_sprite.offset = Vector2(0, -6)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	_marker = Label.new()
	_marker.text = "!"
	_marker.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	_marker.add_theme_color_override("font_outline_color", Color.BLACK)
	_marker.add_theme_constant_override("outline_size", 3)
	_marker.add_theme_font_size_override("font_size", 10)
	_marker.position = Vector2(-3, -38)
	add_child(_marker)
	# Nome que aparece quando o Ifrit chega perto.
	_name_label = Label.new()
	_name_label.text = data.get("nome", "")
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_name_label.add_theme_constant_override("outline_size", 3)
	_name_label.add_theme_font_size_override("font_size", 7)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.custom_minimum_size.x = 80
	_name_label.position = Vector2(-40, -31 if _skin else -26)
	_name_label.modulate.a = 0.0
	add_child(_name_label)
	refresh_marker()
	GameState.changed.connect(refresh_marker)


func current_dialog() -> Dictionary:
	for fala in data.get("falas", []):
		if GameState.check(fala.get("se")):
			return fala
	return {}


func refresh_marker() -> void:
	_marker.visible = current_dialog().get("importante", false)
	# Sprite alternativo quando uma condição vale (ex.: chama restaurada).
	if data.has("sprite_alt") and GameState.check(data.sprite_alt.se):
		_sprite.texture = load(data.sprite_alt.sprite)


func face(direction: Vector2) -> void:
	if _skin:
		_skin.set_direction(direction)
	elif absf(direction.x) > 0.5:
		_sprite.flip_h = direction.x < 0


func _physics_process(delta: float) -> void:
	_time += delta
	_marker.position.y = -38 + sin(_time * 4.0) * 1.5
	var player := get_tree().get_first_node_in_group("jogador") as Node2D
	var near := player != null and player.global_position.distance_to(global_position) < 48.0
	_name_label.modulate.a = move_toward(_name_label.modulate.a, 1.0 if near else 0.0, delta * 5.0)
	_update_swim()
	if not _home_checked:
		_home_checked = true
		_home_in_water = _is_water(_home)
	if not wander:
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 4.0)
		_wander_dir = Vector2.ZERO if randf() < 0.5 else Vector2.from_angle(randf() * TAU)
		if global_position.distance_to(_home) > 32:
			_wander_dir = (_home - global_position).normalized()
		face(_wander_dir)
	# Quem nasceu na água (crianças no canal) passeia só pela água.
	if _home_in_water and _wander_dir != Vector2.ZERO and not _is_water(global_position + _wander_dir * 8.0):
		_wander_dir = Vector2.ZERO if global_position.distance_to(_home) < 4.0 else (_home - global_position).normalized()
	velocity = _wander_dir * (14.0 if _swimming else 20.0)
	move_and_slide()
	if not _swimming and not _skin:
		_sprite.position.y = -absf(sin(_time * 10.0)) if velocity.length() > 1.0 else 0.0


var _swimming := false
var _home_in_water := false
var _home_checked := false


func _is_water(pos: Vector2) -> bool:
	var tiles := get_tree().get_first_node_in_group("terreno") as TileLayer
	return tiles != null and tiles.terrain_at(pos) == TileLayer.WATER


## Na água só aparece da cintura para cima, balançando, com ondinhas em volta.
func _update_swim() -> void:
	var tiles := get_tree().get_first_node_in_group("terreno") as TileLayer
	var now := tiles != null and tiles.terrain_at(global_position) == TileLayer.WATER
	if now != _swimming:
		_swimming = now
		if _skin:
			_skin.swimming = now
			queue_redraw()
			return
		_sprite.region_enabled = now
		_sprite.region_rect = Rect2(0, 0, _sprite.texture.get_width(), 9)
		_sprite.offset = Vector2(0, -5.5) if now else Vector2(0, -6)
		queue_redraw()
	if _swimming:
		if not _skin:
			_sprite.position.y = sin(_time * 4.0 + _home.x) * 0.8
		queue_redraw()


func _draw() -> void:
	if _swimming:
		var wave := 0.5 + 0.5 * sin(_time * 5.0 + _home.x)
		draw_arc(Vector2.ZERO, 7.0 + wave * 2.0, PI, TAU, 12, Color(1, 1, 1, 0.6 - wave * 0.3), 1.0)
		draw_arc(Vector2(0, 1), 10.0 + wave * 3.0, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.35 - wave * 0.2), 1.0)


## Usado pelas cutscenes para mover o NPC até um ponto.
func walk_to(target: Vector2, speed := 50.0) -> void:
	wander = false
	face(target - global_position)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "global_position", target, global_position.distance_to(target) / speed)
	await tween.finished
