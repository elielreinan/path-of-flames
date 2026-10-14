class_name CharacterSprite
## Monta sprites 16x16 de personagens a partir de uma "aparência" (estilo de cabelo, corpo e cores).
## É a base da personalização estilo Graal: cabeça e corpo trocáveis.

const HEADS := {
	"curto": [
		"................",
		".....hhhhhh.....",
		"....hhhhhhhh....",
		"....yyyyyyyy....",
		"....hsssssss....",
		"....skssssks....",
		"....ssssssss....",
		".....ssmmss.....",
	],
	"longo": [
		"................",
		".....hhhhhh.....",
		"....hhhhhhhh....",
		"...hhyyyyyyhh...",
		"...hhsssssshh...",
		"...hskssssksh...",
		"...hssssssssh...",
		"...hhssmmsshh...",
	],
	"veu": [
		"................",
		".....yyyyyy.....",
		"....yyyyyyyy....",
		"...yyyyyyyyyy...",
		"...yyssssssyy...",
		"...yskssssksy...",
		"...yssssssssy...",
		"...yyssmmssyy...",
	],
	"careca": [
		"................",
		"................",
		".....ssssss.....",
		"....ssssssss....",
		"....hsssssshh...",
		"....skssssks....",
		"....ssssssss....",
		".....ssmmss.....",
	],
	"turbante": [
		"................",
		"....yyyyyyyy....",
		"...yyyayyyyyy...",
		"....yyyyyyyy....",
		"....hsssssss....",
		"....skssssks....",
		"....ssssssss....",
		".....ssmmss.....",
	],
	"capuz": [
		"................",
		".....bbbbbb.....",
		"....bbbbbbbb....",
		"...bbbbbbbbbb...",
		"...bbkkkkkkbb...",
		"...bbkykkykbb...",
		"...bbkkkkkkbb...",
		"....bbkkkkbb....",
	],
}

const BODIES := {
	"tunica": [
		"....bbbbbbbb....",
		"...sbbbbbbbbs...",
		"...sbaaaaaabs...",
		"....bbbbbbbb....",
		"....ddd..ddd....",
		"....ddd..ddd....",
		"....fff..fff....",
		"................",
	],
	"manto": [
		"....bbbbbbbb....",
		"...sbbbbbbbbs...",
		"...sbaaaaaabs...",
		"....bbbbbbbb....",
		"...bbbbbbbbbb...",
		"...bbbbbbbbbb...",
		"....ff....ff....",
		"................",
	],
	"armadura": [
		"...aabbbbbbaa...",
		"...abbbbbbbba...",
		"...sbaaaaaabs...",
		"....bbbbbbbb....",
		"....ddd..ddd....",
		"....ddd..ddd....",
		"....fff..fff....",
		"................",
	],
	"crianca": [
		"................",
		"....bbbbbbbb....",
		"...sbbbbbbbbs...",
		"....bbaaaabb....",
		"....dd....dd....",
		"....ff....ff....",
		"................",
		"................",
	],
}

const DEFAULT_COLORS := {
	"h": "#3a2418", "y": "#3a2418", "s": "#e6aa78", "k": "#281410", "m": "#aa5a46",
	"b": "#6e6e78", "a": "#c8a03c", "d": "#5a3c28", "f": "#281912", "B": "#dcdcdc",
}

static var _cache := {}


static func make(look: Dictionary) -> Texture2D:
	var key := JSON.stringify(look)
	if _cache.has(key):
		return _cache[key]
	var colors := DEFAULT_COLORS.duplicate()
	colors.merge(look.get("cores", {}), true)
	if not look.get("cores", {}).has("y"):
		colors.y = colors.h
	var rows: Array = HEADS.get(look.get("cabelo", "curto"), HEADS.curto).duplicate()
	rows.append_array(BODIES.get(look.get("corpo", "tunica"), BODIES.tunica))
	if look.get("crianca", false):
		rows = HEADS.get(look.get("cabelo", "curto"), HEADS.curto).duplicate()
		rows.append_array(BODIES.crianca)
	if look.get("barba", false):
		rows[7] = "....sBBBBBBs...."
		rows[8] = rows[8].substr(0, 5) + "BBBBBB" + rows[8].substr(11)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		var row: String = rows[y]
		for x in mini(row.length(), 16):
			var ch := row[x]
			if ch != ".":
				image.set_pixel(x, y, Color.html(colors.get(ch, "#ff00ff")))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture
