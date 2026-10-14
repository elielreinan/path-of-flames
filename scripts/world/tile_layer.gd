class_name TileLayer
extends Node2D
## Desenha o mapa a partir das linhas de texto do JSON e cria as colisões.
## Visual Sunnyside: cada caractere tem 16 variações (linhas do atlas) conforme os vizinhos.

const TILE := 16
## Cada caractere corresponde a uma coluna de assets/cenario/tiles_sunny.png (gerado por arte/cenario/gerar_cenario.py).
## Linha = máscara dos vizinhos de outro grupo: N=1, L=2, S=4, O=8.
const TILE_CHARS := ".,:fc#HRTWrmbDXCS JPKwghE=*"
const SOLID := "#HRTWrmbXCS JKwhE"
## Água: o Ifrit nada, inimigos que andam e NPCs não entram.
const WATER := "W"
const WATER_LAYER := 1 << 4
## Velocidade de quem anda em cada chão (1 = normal).
const SPEED := {".": 0.85, ":": 1.12, "=": 1.12, "W": 0.55}
const ATLAS := preload("res://assets/cenario/tiles_sunny.png")
## Objetos desenhados por cima do chão vizinho (uma coluna por caractere).
const OBJETOS := "TrmbCSKhE*"
const OBJ_ATLAS := preload("res://assets/cenario/objetos_sunny.png")
## Chãos que podem ficar embaixo de um objeto.
const CHAO := ".,:fcP"
## Caracteres que se emendam entre si (grama+flores, água+ponte, parede+janela+porta).
const GRUPO := {",": ",", "*": ",", "W": "W", "=": "W", "H": "H", "J": "H", "D": "H"}
const ARVORE_PALMEIRA := preload("res://assets/cenario/arvore_palmeira.png")
const ARVORE_REDONDA := preload("res://assets/cenario/arvore_redonda.png")
const ARVORE_PINHEIRO := preload("res://assets/cenario/arvore_pinheiro.png")
## Mapas de serra/frio usam pinheiro.
const MAPAS_PINHEIRO := ["vale_ventos", "trilha_penhascos", "desfiladeiro_sal", "cidadela_sal", "trono_cinzento"]

var rows: Array = []
var map_id := ""


func map_size() -> Vector2i:
	var width := 0
	for row in rows:
		width = maxi(width, row.length())
	return Vector2i(width, rows.size())


func _char(x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return ""
	return rows[y][x]


func _grupo(ch: String) -> String:
	return GRUPO.get(ch, ch)


func _mascara(x: int, y: int) -> int:
	var g := _grupo(_char(x, y))
	var mask := 0
	var dirs := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for i in 4:
		var n := _char(x + dirs[i].x, y + dirs[i].y)
		if n == "" or OBJETOS.contains(n):
			continue
		if _grupo(n) != g:
			mask |= 1 << i
	return mask


## Chão mais comum em volta (lados valem 2, diagonais 1).
func _chao_vizinho(x: int, y: int) -> String:
	var conta := {}
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var n := _char(x + dx, y + dy)
			if n != "" and CHAO.contains(n):
				conta[n] = conta.get(n, 0) + (2 if dx == 0 or dy == 0 else 1)
	var melhor := "."
	var maior := 0
	for k in conta:
		if conta[k] > maior:
			maior = conta[k]
			melhor = k
	return melhor


func _arvore_padrao() -> Texture2D:
	if map_id in MAPAS_PINHEIRO:
		return ARVORE_PINHEIRO
	var flat := "".join(PackedStringArray(rows))
	return ARVORE_REDONDA if flat.count(",") > flat.count(".") else ARVORE_PALMEIRA


## Árvores altas viram Sprite2D para entrar no y-sort das entidades (o Ifrit passa por trás da copa).
func tall_sprites() -> Array[Sprite2D]:
	var out: Array[Sprite2D] = []
	var padrao := _arvore_padrao()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] != "T":
				continue
			var tex: Texture2D = ARVORE_PALMEIRA if _chao_vizinho(x, y) == "." else padrao
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.position = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			s.offset = Vector2(-floorf(tex.get_width() / 2.0), 2 - tex.get_height())
			s.material = _sway_material()
			out.append(s)
	return out


static var _sway: ShaderMaterial


## Vento nas árvores: um material só para todas.
static func _sway_material() -> ShaderMaterial:
	if _sway == null:
		_sway = ShaderMaterial.new()
		_sway.shader = preload("res://shaders/balanco.gdshader")
	return _sway


func is_solid(cell: Vector2i) -> bool:
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return true
	return SOLID.contains(rows[cell.y][cell.x])


## Caractere do tile numa posição do mapa (espaço = fora do mapa).
func terrain_at(pos: Vector2) -> String:
	var cell := Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))
	if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= rows[cell.y].length():
		return " "
	return rows[cell.y][cell.x]


func _ready() -> void:
	z_index = -10
	add_to_group("terreno")
	# Ondas: só em mapas com água (o shader mexe nos pixels azulados do chão).
	if "".join(PackedStringArray(rows)).contains(WATER):
		var water := ShaderMaterial.new()
		water.shader = preload("res://shaders/agua.gdshader")
		material = water
	_build_collision()


var _baked_tex: Texture2D

## Imagem assada do mapa (tools/assar_cenario.py): bordas orgânicas, praia em degradê, paredões e interiores.
## Sem ela, cai no desenho tile a tile pelo atlas.
func _baked() -> Texture2D:
	var path := "res://assets/cenario/mapas/%s.png" % map_id
	if map_id != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _draw() -> void:
	# Guarda a imagem num campo: o desenho só guarda o RID, e uma variável local
	# deixaria a textura ser liberada (aparecia tudo branco).
	if _baked_tex == null:
		_baked_tex = _baked()
	if _baked_tex:
		draw_texture(_baked_tex, Vector2.ZERO)
		return
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch: String = row[x]
			var dest := Rect2(x * TILE, y * TILE, TILE, TILE)
			var obj := OBJETOS.find(ch)
			if obj >= 0:
				var chao := TILE_CHARS.find(_chao_vizinho(x, y))
				draw_texture_rect_region(ATLAS, dest, Rect2(chao * TILE, 0, TILE, TILE))
				if ch != "T":
					draw_texture_rect_region(OBJ_ATLAS, dest, Rect2(obj * TILE, 0, TILE, TILE))
				continue
			var index := TILE_CHARS.find(ch)
			if index < 0:
				index = 0
			draw_texture_rect_region(ATLAS, dest, Rect2(index * TILE, _mascara(x, y) * TILE, TILE, TILE))


func _blocks(cell: Vector2i, water: bool) -> bool:
	var ch: String = rows[cell.y][cell.x] if cell.x < rows[cell.y].length() else " "
	return ch == WATER if water else (SOLID.contains(ch) and ch != WATER)


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	var water_body := StaticBody2D.new()
	water_body.collision_layer = WATER_LAYER
	add_child(water_body)
	var size := map_size()
	# Junta tiles sólidos vizinhos na mesma linha num só retângulo (a água vai numa camada própria).
	for y in size.y:
		for water in [false, true]:
			_build_row(water_body if water else body, y, size.x, water)
	_build_borders(body)


func _build_row(body: StaticBody2D, y: int, width: int, water: bool) -> void:
	var x := 0
	while x < width:
		if not _blocks(Vector2i(x, y), water):
			x += 1
			continue
		var start := x
		while x < width and _blocks(Vector2i(x, y), water):
			x += 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2((x - start) * TILE, TILE)
		shape.shape = rect
		shape.position = Vector2((start + x) * TILE / 2.0, y * TILE + TILE / 2.0)
		body.add_child(shape)


func _build_borders(body: StaticBody2D) -> void:
	var size := map_size()
	# Bordas do mapa.
	for rect in [Rect2(-TILE, -TILE, (size.x + 2) * TILE, TILE), Rect2(-TILE, size.y * TILE, (size.x + 2) * TILE, TILE),
			Rect2(-TILE, 0, TILE, size.y * TILE), Rect2(size.x * TILE, 0, TILE, size.y * TILE)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		body.add_child(shape)
