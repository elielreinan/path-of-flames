extends Node
## Carrega todo o conteúdo do jogo (JSON em res://data).

var items := {}
var enemies := {}
var quests := {}
var npcs := {}
var shops := {}
var dialogs := {}
var cutscenes := {}
var currencies := {}
## Mapa geral: regiões com retângulo no mundo, ordem na história e tipo de terreno.
var world := {}
## Combinações da bolsa: [{a, b, r}].
var recipes: Array = []
## Montarias: id -> {nome, sprite, domar (inimigo), isca (item)}.
var mounts := {}
var secrets := {}
## Criaturas desenhadas (arte/criaturas): id -> {arquivo, tipo, frame, anims, pe, sela}.
var creatures := {}
var _maps := {}


func _ready() -> void:
	items = _load("res://data/itens.json")
	enemies = _load("res://data/inimigos.json")
	quests = _load("res://data/missoes.json")
	npcs = _load("res://data/npcs.json")
	shops = _load("res://data/lojas.json")
	currencies = _load("res://data/moedas.json")
	world = _load("res://data/mundo.json")
	recipes = _load("res://data/receitas.json").get("receitas", [])
	mounts = _load("res://data/montarias.json")
	dialogs = _load_dir("res://data/dialogos")
	cutscenes = _load_dir("res://data/cutscenes")
	if FileAccess.file_exists("res://data/criaturas.json"):
		creatures = _load("res://data/criaturas.json")
	if FileAccess.file_exists("res://data/segredos.json"):
		secrets = _load("res://data/segredos.json")


func item(id: String) -> Dictionary:
	return items.get(id, {"nome": id, "tipo": "material", "descricao": "", "preco": 0})


func mount(id: String) -> Dictionary:
	return mounts.get(id, {})


func map(id: String) -> Dictionary:
	if not _maps.has(id):
		_maps[id] = _load("res://data/mapas/%s.json" % id)
	return _maps[id]


## Região do mapa geral a que um mapa pertence (casas e palácio contam como a cidade).
func region_of(id: String) -> String:
	if world.get("regioes", {}).has(id):
		return id
	if world.get("pais", {}).has(id):
		return world.pais[id]
	if id.begins_with("lar_"):
		return id.trim_prefix("lar_").left(id.trim_prefix("lar_").rfind("_"))
	return ""


func currency_name(id: String) -> String:
	return currencies.get(id, {}).get("nome", id)


func _load(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Arquivo não encontrado: " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON inválido: " + path)
		return {}
	return parsed


func _load_dir(dir_path: String) -> Dictionary:
	var result := {}
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".json"):
			result.merge(_load(dir_path.path_join(file_name)))
	return result
