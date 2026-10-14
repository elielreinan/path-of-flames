class_name CreatureSprite
extends Sprite2D
## Criaturas desenhadas no estilo Sunnyside (arte/criaturas): bichos, chefes e montarias.
## Folha com uma linha por animação, olhando para a direita (o jogo espelha). Dados em data/criaturas.json.

var info := {}
var anim := ""
var anim_frame := 0
## Animação sem repetição chegou no último quadro.
var done := false
## Troca sozinha entre parado e andar conforme o dono se move, e vira para o lado do movimento.
var auto := true
## Animação de movimento usada pelo modo automático (montaria correndo usa "correr").
var move_anim := "andar"

var _time := 0.0
var _last_pos := Vector2.INF


static func has(id: String) -> bool:
	return Data.creatures.has(id) and ResourceLoader.exists(_path(id))


static func _path(id: String) -> String:
	return "res://assets/criaturas/" + str(Data.creatures[id].arquivo)


static func create(id: String) -> CreatureSprite:
	var sprite := CreatureSprite.new()
	sprite.info = Data.creatures[id]
	sprite.texture = load(_path(id))
	var frame_size := frame_size_of(id)
	sprite.hframes = int(sprite.texture.get_width() / frame_size.x)
	sprite.vframes = int(sprite.texture.get_height() / frame_size.y)
	# O "pe" (centro da sombra) fica na origem do nó.
	sprite.offset = frame_size / 2.0 - Vector2(sprite.info.pe[0], sprite.info.pe[1])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("parado")
	return sprite


## Retrato para os diálogos: o primeiro quadro parado.
static func portrait(id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(_path(id))
	var size := frame_size_of(id)
	atlas.region = Rect2(Vector2.ZERO, size)
	return atlas


static func frame_size_of(id: String) -> Vector2:
	var f: Array = Data.creatures[id].frame
	return Vector2(f[0], f[1])


## Ponto da sela em relação ao pé (montarias), já considerando o espelho.
func saddle() -> Vector2:
	var s: Array = info.get("sela", info.pe)
	var v := Vector2(s[0] - info.pe[0], s[1] - info.pe[1])
	if flip_h:
		v.x = -v.x
	return v * scale


## Altura visível acima do pé (barra de vida e nome).
func visible_height() -> float:
	return float(info.pe[1]) - 4.0


func has_anim(name: String) -> bool:
	return info.anims.has(name)


func play(name: String, restart := false) -> void:
	if not has_anim(name):
		return
	if name == anim and not restart:
		return
	anim = name
	anim_frame = 0
	_time = 0.0
	done = false
	_apply()


func face(v: Vector2) -> void:
	if absf(v.x) > 0.5:
		flip_h = v.x < 0


func _process(delta: float) -> void:
	if auto:
		_auto_anim(delta)
	if anim == "":
		return
	var a: Array = info.anims[anim]
	_time += delta
	var step := 1.0 / maxf(float(a[2]), 0.1)
	if _time < step:
		return
	var loops := anim in ["parado", "andar", "correr"]
	while _time >= step:
		_time -= step
		if anim_frame < int(a[1]) - 1:
			anim_frame += 1
		elif loops:
			anim_frame = 0
		else:
			done = true
	_apply()


func _auto_anim(delta: float) -> void:
	var holder := get_parent() as Node2D
	if holder == null:
		return
	var pos := holder.global_position
	var moved := Vector2.ZERO if _last_pos == Vector2.INF else pos - _last_pos
	_last_pos = pos
	# Ataque, dano, especial e morte terminam antes de voltar ao normal.
	if anim in ["ataque", "dano", "especial", "morrer", "quebrado"] and not done:
		return
	if anim in ["morrer", "quebrado"]:
		return
	var moving := delta > 0.0 and moved.length() / delta > 4.0
	if moving:
		face(moved)
	play(move_anim if moving and has_anim(move_anim) else "parado")


func _apply() -> void:
	var a: Array = info.anims[anim]
	frame = int(a[0]) * hframes + mini(anim_frame, hframes - 1)


## Cópia que toca a morte sozinha e some (o inimigo em si sai do jogo na hora).
func spawn_death(parent: Node, at: Vector2) -> void:
	if not has_anim("morrer") and not has_anim("quebrado"):
		return
	var corpse := CreatureSprite.new()
	corpse.info = info
	corpse.texture = texture
	corpse.hframes = hframes
	corpse.vframes = vframes
	corpse.offset = offset
	corpse.flip_h = flip_h
	corpse.scale = scale
	corpse.self_modulate = self_modulate
	corpse.texture_filter = texture_filter
	corpse.auto = false
	corpse.position = at
	parent.add_child(corpse)
	corpse.play("morrer" if has_anim("morrer") else "quebrado")
	var tween := corpse.create_tween()
	tween.tween_interval(float(info.anims[corpse.anim][1]) / maxf(float(info.anims[corpse.anim][2]), 0.1) + 0.3)
	tween.tween_property(corpse, "modulate:a", 0.0, 0.4)
	tween.tween_callback(corpse.queue_free)
