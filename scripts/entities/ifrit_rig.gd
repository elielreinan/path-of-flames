class_name IfritRig
extends Node2D
## Visual do Ifrit em camadas (paper-doll): corpo > roupa > cabelo > arma.
## Base: Sunnyside World por Daniel Diggle (modificado). Folhas de 13x44 quadros de 96x64;
## linha = animação + direção (baixo, esquerda, cima, direita), coluna = quadro.

const DIR := "res://assets/personagens/ifrit_sunny/"
const COLS := 13
const ROWS := 44
const FRAME := Vector2i(96, 64)
## Pé do personagem fica nesse ponto do quadro.
const PIVOT := Vector2(48, 40)
## nome: [linha, quadros, fps, repete]
const ANIMS := {
	"parado": [0, 9, 8, true],
	"andar": [4, 8, 10, true],
	"correr": [8, 8, 12, true],
	"golpe": [12, 6, 18, false],
	"dano": [16, 8, 14, false],
	"morrer": [20, 13, 10, false],
	"nadar": [24, 12, 10, true],
	"pular": [28, 9, 14, false],
	"rolar": [32, 10, 16, false],
	"carregar": [36, 8, 10, true],
	"interagir": [40, 8, 12, false],
}

var anim := "parado"
var dir := 0
var frame := 0
## Animação sem repetição chegou no último quadro.
var done := false
var tint := Color.WHITE:
	set(value):
		tint = value
		for layer in [_body, _clothes, _hair, _weapon]:
			if layer:
				layer.self_modulate = value

var _time := 0.0
var _body: Sprite2D
var _clothes: Sprite2D
var _hair: Sprite2D
var _weapon: Sprite2D
var _armor_id := "?"
var _weapon_id := "?"


func _ready() -> void:
	_weapon = _layer(null, 6, 4)
	_body = _layer(load(DIR + "corpo.png"))
	_clothes = _layer(null)
	_hair = _layer(load(DIR + "cabelo_ifrit.png"))
	_weapon.visible = false
	refresh_gear()
	GameState.changed.connect(refresh_gear)
	_apply()


func _layer(texture: Texture2D, hframes := COLS, vframes := ROWS) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.offset = Vector2(FRAME) / 2.0 - PIVOT
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	return sprite


## Troca roupa e espada conforme o que está equipado.
func refresh_gear() -> void:
	if GameState.armor != _armor_id:
		_armor_id = GameState.armor
		_clothes.texture = load(_path("roupa_" + _armor_id + ".png", "roupa_ifrit.png"))
	if GameState.weapon != _weapon_id:
		_weapon_id = GameState.weapon
		_weapon.texture = load(_path("armas/arma_" + _weapon_id + ".png", "armas/arma_sem_arma.png"))


static func _path(file: String, fallback: String) -> String:
	return DIR + file if ResourceLoader.exists(DIR + file) else DIR + fallback


func play(name: String, restart := false) -> void:
	if name == anim and not restart:
		return
	anim = name
	frame = 0
	_time = 0.0
	done = false
	_apply()


func set_direction(v: Vector2) -> void:
	if v.length() < 0.1:
		return
	if absf(v.x) > absf(v.y):
		dir = 1 if v.x < 0 else 3
	else:
		dir = 2 if v.y < 0 else 0
	_apply()


func _process(delta: float) -> void:
	var info: Array = ANIMS[anim]
	_time += delta
	var step := 1.0 / float(info[2])
	while _time >= step:
		_time -= step
		if frame < int(info[1]) - 1:
			frame += 1
		elif info[3]:
			frame = 0
		else:
			done = true
	_apply()


func _apply() -> void:
	if _body == null:
		return
	var info: Array = ANIMS[anim]
	var index := (int(info[0]) + dir) * COLS + mini(frame, COLS - 1)
	for layer in [_body, _clothes, _hair]:
		layer.frame = index
	# Espada só aparece no golpe; olhando para cima (e no começo do golpe de lado) fica atrás do corpo.
	_weapon.visible = anim == "golpe"
	if _weapon.visible:
		_weapon.frame = dir * 6 + mini(frame, 5)
		var behind := dir == 2 or (dir in [1, 3] and frame == 0)
		move_child(_weapon, 0 if behind else get_child_count() - 1)


## Cópia parada do quadro atual (rastro do golpe especial).
func snapshot() -> Node2D:
	var copy := Node2D.new()
	for layer in get_children():
		if layer is Sprite2D and layer.visible and layer.texture:
			var sprite := Sprite2D.new()
			sprite.texture = layer.texture
			sprite.hframes = layer.hframes
			sprite.vframes = layer.vframes
			sprite.frame = layer.frame
			sprite.offset = layer.offset
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			copy.add_child(sprite)
	return copy


## Retrato para os diálogos: rosto e tronco do Ifrit parado, olhando para a frente.
static func portrait() -> Texture2D:
	var out := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var region := Rect2i(36, 18, 24, 24)
	for file in ["corpo.png", _path("roupa_" + GameState.armor + ".png", "roupa_ifrit.png").get_file(), "cabelo_ifrit.png"]:
		var tex: Texture2D = load(DIR + file)
		if tex == null:
			continue
		var image := tex.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		out.blend_rect(image, region, Vector2i.ZERO)
	return ImageTexture.create_from_image(out)
