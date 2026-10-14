class_name CreatureSprite
extends Sprite2D
## Criaturas desenhadas no estilo Sunnyside (arte/criaturas): bichos, chefes e montarias.
## Folha com uma linha por animação, olhando para a direita (o jogo espelha). Dados em data/criaturas.json.
## Montarias têm 4 direções ("dirs"): animação "andar" vira "andar_baixo" etc., sem espelhar,
## e uma camada da frente (cabeça de frente) que o dono desenha por cima do cavaleiro.

var info := {}
var anim := ""
var anim_frame := 0
## Animação sem repetição chegou no último quadro.
var done := false
## Troca sozinha entre parado e andar conforme o dono se move, e vira para o lado do movimento.
var auto := true
## Animação de movimento usada pelo modo automático (montaria correndo usa "correr").
var move_anim := "andar"
## Coluna da variante (objetos com várias versões na mesma folha, como as estátuas).
var column := 0
## Direção atual (só montarias com 4 direções).
var dir := "direita"
## Camada da frente (cabeça/pescoço de frente); o dono põe por cima do cavaleiro.
var front: Sprite2D

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
	if sprite.info.has("camada_frente"):
		var front_path := "res://assets/criaturas/" + str(sprite.info.camada_frente)
		if ResourceLoader.exists(front_path):
			sprite.front = Sprite2D.new()
			sprite.front.texture = load(front_path)
			sprite.front.hframes = sprite.hframes
			sprite.front.vframes = sprite.vframes
			sprite.front.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("parado")
	return sprite


## Retrato para os diálogos: o primeiro quadro parado.
static func portrait(id: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(_path(id))
	var size := frame_size_of(id)
	var row := 0
	if Data.creatures[id].has("dirs"):
		row = int(Data.creatures[id].anims.parado_direita[0])
	atlas.region = Rect2(Vector2(0, row * size.y), size)
	return atlas


static func frame_size_of(id: String) -> Vector2:
	var f: Array = Data.creatures[id].frame
	return Vector2(f[0], f[1])


## Ponto da sela em relação ao pé (montarias), já considerando o espelho.
func saddle() -> Vector2:
	if directional():
		var seat: Array = info.sela[dir]
		var foot: Array = info.pe_dir[dir]
		return Vector2(seat[0] - foot[0], seat[1] - foot[1]) * scale
	var s: Array = info.get("sela", info.pe)
	var v := Vector2(s[0] - info.pe[0], s[1] - info.pe[1])
	if flip_h:
		v.x = -v.x
	return v * scale


## Altura visível acima do pé (barra de vida e nome).
func visible_height() -> float:
	return float(info.pe[1]) - 4.0


func directional() -> bool:
	return info.has("dirs")


func has_anim(name: String) -> bool:
	return info.anims.has(name + "_direita" if directional() else name)


## Linha da folha da animação atual (com a direção, nas montarias).
func _key() -> String:
	return anim + "_" + dir if directional() else anim


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
	if directional():
		if v.length() < 0.1:
			return
		var new_dir := ("esquerda" if v.x < 0 else "direita") if absf(v.x) >= absf(v.y) else ("cima" if v.y < 0 else "baixo")
		if new_dir != dir:
			dir = new_dir
			var foot: Array = info.pe_dir[dir]
			offset = frame_size_of_info() / 2.0 - Vector2(foot[0], foot[1])
			if anim != "":
				_apply()
		return
	if absf(v.x) > 0.5:
		flip_h = v.x < 0


func frame_size_of_info() -> Vector2:
	return Vector2(info.frame[0], info.frame[1])


## Troca a folha por outra criatura do mesmo tamanho (ex.: chama fraca -> chama sagrada).
func swap(id: String) -> void:
	info = Data.creatures[id]
	texture = load(_path(id))
	play("parado", true)


func _process(delta: float) -> void:
	if auto:
		_auto_anim(delta)
	if anim == "":
		return
	var a: Array = info.anims[_key()]
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
	var a: Array = info.anims[_key()]
	frame = int(a[0]) * hframes + mini(anim_frame + column, hframes - 1)
	if front:
		front.frame = frame
		front.offset = offset
		front.position = position
		front.visible = visible and bool(info.get("frente_do_cavaleiro", {}).get(dir, false))


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
	var death: Array = info.anims[corpse._key()]
	tween.tween_interval(float(death[1]) / maxf(float(death[2]), 0.1) + 0.3)
	tween.tween_property(corpse, "modulate:a", 0.0, 0.4)
	tween.tween_callback(corpse.queue_free)
