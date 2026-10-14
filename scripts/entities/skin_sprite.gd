class_name SkinSprite
extends Sprite2D
## Skin estilo Sunnyside de NPCs, aliados e inimigos humanos: uma folha só, já montada.
## Folhas compactadas por tools/compactar_skins.py: 13 colunas de quadros 48x40,
## linha = animação + direção (baixo, esquerda, cima, direita). Base: Sunnyside World (Daniel Diggle).

const COLS := 13
const FRAME := Vector2i(48, 40)
## Pé do personagem fica nesse ponto do quadro.
const PIVOT := Vector2(24, 26)
## nome: [linha, quadros, fps, repete] (mesma ordem de tools/compactar_skins.py)
const ANIMS := {
	"parado": [0, 9, 8, true],
	"andar": [4, 8, 10, true],
	"golpe": [8, 6, 18, false],
	"dano": [12, 8, 14, false],
	"morrer": [16, 13, 10, false],
	"nadar": [20, 12, 10, true],
}
## Altura visível do personagem acima do pé (para barra de vida, nome e marcador).
const HEIGHT := 18.0

var anim := "parado"
var dir := 0
var anim_frame := 0
## Animação sem repetição chegou no último quadro.
var done := false

## Troca sozinha entre parado, andar e nadar conforme o dono se move (vale também nas cenas).
var auto := true
var swimming := false

var _time := 0.0
var _last_pos := Vector2.INF


## Skin do personagem, ou null quando não há arquivo (aí o jogo usa o CharacterSprite antigo).
static func sheet_for(kind: String, id: String) -> Texture2D:
	var path := "res://assets/personagens/%s/%s.png" % [kind, id]
	return load(path) if ResourceLoader.exists(path) else null


static func create(sheet: Texture2D) -> SkinSprite:
	var sprite := SkinSprite.new()
	sprite.texture = sheet
	sprite.hframes = COLS
	sprite.vframes = int(sheet.get_height() / FRAME.y)
	sprite.offset = Vector2(FRAME) / 2.0 - PIVOT
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Anima mesmo com o jogo pausado nas cenas (os NPCs andam por tween).
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite._apply()
	return sprite


## Retrato para os diálogos (arquivo pequeno gerado junto com a folha), ou null.
static func portrait(id: String) -> Texture2D:
	var path := "res://assets/personagens/retratos/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


func play(name: String, restart := false) -> void:
	if name == anim and not restart:
		return
	anim = name
	anim_frame = 0
	_time = 0.0
	done = false
	_apply()


func set_direction(v: Vector2) -> void:
	if v.length() < 0.1:
		return
	var new_dir := dir
	if absf(v.x) > absf(v.y):
		new_dir = 1 if v.x < 0 else 3
	else:
		new_dir = 2 if v.y < 0 else 0
	if new_dir != dir:
		dir = new_dir
		_apply()


func _process(delta: float) -> void:
	if auto:
		_auto_anim(delta)
	var info: Array = ANIMS[anim]
	_time += delta
	var step := 1.0 / float(info[2])
	if _time < step:
		return
	while _time >= step:
		_time -= step
		if anim_frame < int(info[1]) - 1:
			anim_frame += 1
		elif info[3]:
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
	# Golpe, dano e morte terminam antes de voltar ao normal.
	if anim in ["golpe", "dano", "morrer"] and not done:
		return
	if anim == "morrer":
		return
	var moving := delta > 0.0 and moved.length() / delta > 4.0
	if moving:
		set_direction(moved)
	play("nadar" if swimming else ("andar" if moving else "parado"))


func _apply() -> void:
	var info: Array = ANIMS[anim]
	frame = (int(info[0]) + dir) * COLS + mini(anim_frame, COLS - 1)
