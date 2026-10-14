extends Node
## Estado do jogador e da história: nível, vida, inventário, moedas, missões, flags e aliados.

signal changed
signal toast(text: String)
## Missão terminou (concluída ou falhou): a tela especial mostra o resultado.
signal quest_finished(id: String, success: bool, details: Array)
signal leveled_up(level: int)
## Antídoto ou elixir: o Ifrit perde os efeitos de status.
signal status_cured
signal rank_changed(rank_name: String)

## Classes: só dá para escolher uma, e é para sempre.
const CLASSES := {
	"guerreiro": {"nome": "Guerreiro", "descricao": "Golpe 30% mais forte, +12 de vida e Fúria que enche mais rápido.",
		"ataque": 1.3, "vida": 12, "furia": 1.35},
	"feiticeiro": {"nome": "Feiticeiro", "descricao": "Magia 50% mais forte e bola de fogo que recarga quase na metade do tempo.",
		"magia": 1.5, "fogo": 0.55},
	"clerigo": {"nome": "Clérigo", "descricao": "Recupera vida aos poucos, poções curam 50% a mais e não é envenenado.",
		"regen": 4.0, "cura": 1.5, "imune": "veneno"},
}
## Hierarquia por feitos: [pontos mínimos, título].
const RANKS := [[0, "Aprendiz"], [25, "Andarilho"], [70, "Guardião"], [130, "Campeão"], [200, "Lenda das Chamas"]]
## Honra: [mínimo, título].
const HONOR_TITLES := [[0, "Desonrado"], [20, "Suspeito"], [40, "Comum"], [60, "Respeitado"], [80, "Herói do Povo"]]

const SAVE_PATH := "user://save.json"
const MAX_LEVEL := 80
## Versão do balanceamento de níveis (2 = 1º chefe no nível 15, máximo 80).
const BALANCE := 2
## Tamanho da bolsa em células (colunas x linhas) por nível de bolsa.
const BAG_SIZES := [Vector2i(6, 4), Vector2i(7, 4), Vector2i(8, 5)]

var flags := {}
var quests := {}  # id -> {"estado": "ativa"|"pronta"|"concluida", "progresso": [int]}
var inventory := {}  # item_id -> quantidade
var wallet := {}  # moeda -> quantidade
var weapon := ""
var armor := ""
## Itens comuns na grade da bolsa: {id, x, y, r (girado), n (quantidade)}.
var grid: Array = []
## Baú: itens guardados (id -> quantidade).
var storage := {}
var bag_level := 0
## Espera entre um consumível e outro (não dá para beber poções sem parar no meio da luta).
const ITEM_COOLDOWN := 1.5
var item_cooldown := 0.0
var level := 1
var xp := 0
var hp := 10
var allies: Array = []
var map_id := ""
var spawn_id := ""
## Item do botão de acesso rápido.
var quick_item := "pocao_pequena"
## Honra de 0 a 100 (começa em 50). Boas ações aumentam, más ações diminuem.
var honra := 50
var classe := ""
## Regiões do mapa geral já visitadas (id -> true).
var visited := {}
## Barra de Fúria do golpe especial: enche acertando e derrotando inimigos.
const FURY_MAX := 100.0
const FURY_PER_HIT := 7.0
const FURY_PER_KILL := 12.0
var fury := 0.0
## Montarias: as que o Ifrit tem e a que ele chama ao montar.
var mounts: Array = []
var mount := ""
## Se o Ifrit estava montado (continua montado ao trocar de mapa; não vai para o save).
var riding := false


func _process(delta: float) -> void:
	item_cooldown = maxf(item_cooldown - delta, 0.0)


func new_game() -> void:
	flags = {}
	quests = {}
	inventory = {"pocao_pequena": 2, "espada_madeira": 1}
	wallet = {"brasas": 10}
	weapon = "espada_madeira"
	armor = ""
	storage = {}
	bag_level = 0
	level = 1
	xp = 0
	hp = max_hp()
	allies = []
	map_id = "casa_mae"
	spawn_id = "inicio"
	quick_item = "pocao_pequena"
	honra = 50
	classe = ""
	visited = {}
	fury = 0.0
	mounts = []
	mount = ""
	_rebuild_grid()
	changed.emit()


# ---------- Atributos ----------

func max_hp() -> int:
	return 10 + level * 3 + int(class_bonus("vida", 0))


func attack_power() -> int:
	var bonus := int(Data.item(weapon).get("dano", 0)) if weapon != "" else 0
	return roundi((2 + int(level * 0.6) + bonus * 3) * class_bonus("ataque", 1.0))


func magic_power() -> int:
	return roundi((3 + int(level * 0.8)) * class_bonus("magia", 1.0))


func class_bonus(key: String, default: float) -> float:
	return float(CLASSES.get(classe, {}).get(key, default))


func set_class(id: String) -> void:
	if classe != "" or not CLASSES.has(id):
		return
	classe = id
	hp = max_hp()
	toast.emit("Agora você é %s!" % CLASSES[id].nome)
	changed.emit()


# ---------- Honra e hierarquia ----------

func add_honor(amount: int, announce := true) -> void:
	var before := honra
	honra = clampi(honra + amount, 0, 100)
	if honra != before:
		if announce:
			toast.emit("Honra %+d" % (honra - before))
		changed.emit()


func honor_title() -> String:
	var title := ""
	for entry in HONOR_TITLES:
		if honra >= entry[0]:
			title = entry[1]
	return title


## Compara uma arma ou armadura com a que está em uso. Devolve null se não for equipamento.
func equip_delta(id: String) -> Variant:
	var data := Data.item(id)
	match data.get("tipo"):
		"arma":
			return int(data.get("dano", 0)) - int(Data.item(weapon).get("dano", 0)) if weapon != "" else int(data.get("dano", 0))
		"armadura":
			return int(data.get("defesa", 0)) - int(Data.item(armor).get("defesa", 0)) if armor != "" else int(data.get("defesa", 0))
	return null


func add_fury(amount: float) -> void:
	if not flags.get("golpe_especial", false) or fury >= FURY_MAX:
		return
	var was_full := fury >= FURY_MAX
	var bonus := 1.5 if item_count("olho_zazu") > 0 else 1.0
	fury = minf(FURY_MAX, fury + amount * class_bonus("furia", 1.0) * bonus)
	if fury >= FURY_MAX and not was_full:
		toast.emit("Fúria cheia!")


## Segredos e easter eggs: cada um vale uma vez (lista em data/segredos.json).
func find_secret(id: String) -> void:
	var flag := "segredo_" + id
	if has_flag(flag):
		return
	set_flag(flag)
	toast.emit("Segredo encontrado! (%d/%d)" % [secrets_found(), Data.secrets.size()])


func secrets_found() -> int:
	var count := 0
	for id in Data.secrets:
		if has_flag("segredo_" + id):
			count += 1
	return count


func add_mount(id: String) -> void:
	if not id in mounts:
		mounts.append(id)
	mount = id
	changed.emit()


## Escala de níveis antiga (máx. 30) para a nova (máx. 80). Igual a tools/rebalancear_niveis.py.
static func old_level_to_new(old: int) -> int:
	if old <= 4:
		return 1 + roundi((old - 1) * 14.0 / 3.0)
	return roundi(15 + (old - 4) * 2.6)


## Quantos chefes já caíram: cada um deixa o mundo mais perigoso.
func boss_tier() -> int:
	var tier := 0
	for flag in flags:
		if flag.begins_with("chefe_") and flags[flag]:
			tier += 1
	return tier


## Pontos de feitos: chefes vencidos, missões concluídas e honra.
func deeds() -> int:
	var points := 0
	for flag in flags:
		if flag.begins_with("chefe_"):
			points += 12
	for id in quests:
		if quests[id].estado == "concluida":
			points += 5 if Data.quests[id].get("tipo") == "secundaria" else 2
	return points + honra / 10


func rank() -> String:
	var title := ""
	var points := deeds()
	for entry in RANKS:
		if points >= entry[0]:
			title = entry[1]
	return title


## Preço nas lojas conforme a honra: até 10% de desconto ou 15% mais caro.
func price_factor() -> float:
	if honra >= 80:
		return 0.9
	if honra >= 60:
		return 0.95
	if honra < 20:
		return 1.15
	return 1.0


## Curva de EXP ~40% mais íngreme que a original (10 + 15 por nível): dá para zerar só com a história, mas
## os portões por nível pedem missões secundárias, o Cânion das Feras e o Campo de Treino.
func xp_to_next() -> int:
	return 10 + (level - 1) * 5 + level * level / 8


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	while xp >= xp_to_next() and level < MAX_LEVEL:
		xp -= xp_to_next()
		level += 1
		hp = max_hp()
		leveled_up.emit(level)
	changed.emit()


## EXP por derrotar um inimigo: mais quando ele tem nível maior que o do Ifrit, menos quando é bem mais fraco.
func xp_for_kill(base: int, enemy_level: int) -> int:
	var factor := clampf(1.0 + 0.06 * (enemy_level - level), 0.1, 2.0)
	return maxi(1, roundi(base * factor))


func set_quick_item(id: String) -> void:
	quick_item = id
	changed.emit()


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp())
	changed.emit()


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	changed.emit()


# ---------- Flags e condições ----------

func has_flag(flag: String) -> bool:
	return flags.get(flag, false)


func set_flag(flag: String, value: Variant = true) -> void:
	var rank_before := rank() if flag.begins_with("chefe_") else ""
	flags[flag] = value
	# Requisito do golpe especial: vencer o primeiro chefe.
	if flag == "chefe_rainha" and value and not flags.get("golpe_especial", false):
		flags["golpe_especial"] = true
		fury = FURY_MAX
		toast.emit("Novo golpe: Fúria das Brasas! Encha a barra e toque em ESPECIAL.")
	notify("flag", flag)
	if rank_before != "":
		_check_rank(rank_before)
	changed.emit()


## Avalia uma condição do JSON. Todas as chaves precisam ser verdadeiras.
func check(cond) -> bool:
	if cond == null or (cond is Dictionary and cond.is_empty()):
		return true
	if cond is Array:
		for c in cond:
			if not check(c):
				return false
		return true
	if cond.has("flag") and not has_flag(cond.flag):
		return false
	if cond.has("sem_flag") and has_flag(cond.sem_flag):
		return false
	if cond.has("quest"):
		var states = cond.get("estado", "ativa")
		if states is String:
			states = [states]
		if not quest_state(cond.quest) in states:
			return false
	if cond.has("item") and item_count(cond.item) < int(cond.get("qtd", 1)):
		return false
	if cond.has("nivel") and level < int(cond.nivel):
		return false
	if cond.has("aliado") and not cond.aliado in allies:
		return false
	if cond.has("honra_min") and honra < int(cond.honra_min):
		return false
	if cond.has("honra_max") and honra > int(cond.honra_max):
		return false
	if cond.has("classe") and classe != str(cond.classe):
		return false
	if cond.has("moeda"):
		for currency in cond.moeda:
			if money(currency) < int(cond.moeda[currency]):
				return false
	return true


# ---------- Inventário (bolsa em grade, estilo Resident Evil) e moedas ----------
# `inventory` guarda o total que o Ifrit carrega (grade + equipados + itens importantes).
# Itens comuns ocupam células na `grid`; itens de missão e chaves ficam na lista de importantes.
# O que não cabe vai para o `storage` (baú), que só se abre em cidades e casas.

func is_key_item(id: String) -> bool:
	return Data.item(id).get("tipo", "") in ["missao", "chave"]


func bag_size() -> Vector2i:
	return BAG_SIZES[clampi(bag_level, 0, BAG_SIZES.size() - 1)]


func item_size(id: String, rotated := false) -> Vector2i:
	var data := Data.item(id)
	var default := [1, 3] if data.get("tipo") == "arma" else [2, 2] if data.get("tipo") == "armadura" else [1, 1]
	var t: Array = data.get("tam", default)
	return Vector2i(int(t[1]), int(t[0])) if rotated else Vector2i(int(t[0]), int(t[1]))


func stack_max(id: String) -> int:
	return int(Data.item(id).get("pilha", 1))


func entry_rect(entry: Dictionary) -> Rect2i:
	return Rect2i(Vector2i(int(entry.x), int(entry.y)), item_size(entry.id, entry.get("r", false)))


func fits(id: String, pos: Vector2i, rotated: bool, ignore: Dictionary = {}) -> bool:
	var rect := Rect2i(pos, item_size(id, rotated))
	if rect.position.x < 0 or rect.position.y < 0 or rect.end.x > bag_size().x or rect.end.y > bag_size().y:
		return false
	for entry in grid:
		if entry != ignore and entry_rect(entry).intersects(rect):
			return false
	return true


func entry_at(cell: Vector2i) -> Dictionary:
	for entry in grid:
		if entry_rect(entry).has_point(cell):
			return entry
	return {}


func _free_spot(id: String) -> Dictionary:
	for rotated in [false, true]:
		for y in bag_size().y:
			for x in bag_size().x:
				if fits(id, Vector2i(x, y), rotated):
					return {"x": x, "y": y, "r": rotated}
	return {}


## Põe na grade: completa pilhas existentes e depois usa espaços livres. Devolve quanto coube.
func _grid_insert(id: String, amount: int) -> int:
	var left := amount
	for entry in grid:
		if left <= 0:
			break
		if entry.id == id and entry.n < stack_max(id):
			var add := mini(stack_max(id) - int(entry.n), left)
			entry.n = int(entry.n) + add
			left -= add
	while left > 0:
		var spot := _free_spot(id)
		if spot.is_empty():
			break
		var add := mini(stack_max(id), left)
		grid.append({"id": id, "x": spot.x, "y": spot.y, "r": spot.r, "n": add})
		left -= add
	return amount - left


## Tira da grade, começando pelas pilhas menores. Devolve quanto tirou.
func _grid_take(id: String, amount: int) -> int:
	var stacks := grid.filter(func(e): return e.id == id)
	stacks.sort_custom(func(a, b): return a.n < b.n)
	var left := amount
	for entry in stacks:
		if left <= 0:
			break
		var take := mini(int(entry.n), left)
		entry.n = int(entry.n) - take
		left -= take
		if entry.n <= 0:
			grid.erase(entry)
	return amount - left


func grid_count(id: String) -> int:
	var total := 0
	for entry in grid:
		if entry.id == id:
			total += int(entry.n)
	return total


## Total do item, contando o baú (para missões de coleta e entregas).
func item_count(id: String) -> int:
	return inventory.get(id, 0) + storage.get(id, 0)


func _add_count(dict: Dictionary, id: String, amount: int) -> void:
	dict[id] = dict.get(id, 0) + amount
	if dict[id] <= 0:
		dict.erase(id)


func add_item(id: String, amount := 1, announce := true) -> void:
	if amount <= 0:
		return
	var data := Data.item(id)
	if data.get("tipo") == "bolsa":
		if int(data.get("nivel", 0)) > bag_level:
			bag_level = int(data.nivel)
			toast.emit("Bolsa maior: %d x %d!" % [bag_size().x, bag_size().y])
		changed.emit()
		return
	var placed := amount if is_key_item(id) else _grid_insert(id, amount)
	_add_count(inventory, id, placed)
	if placed < amount:
		_add_count(storage, id, amount - placed)
		toast.emit("Bolsa cheia: %s foi para o baú." % data.nome)
	elif announce:
		toast.emit("+%d %s" % [amount, data.nome])
	_refresh_collect_objectives()
	changed.emit()


func remove_item(id: String, amount := 1) -> bool:
	if item_count(id) < amount:
		return false
	var left := amount
	if is_key_item(id):
		var take := mini(inventory.get(id, 0), left)
		_add_count(inventory, id, -take)
		left -= take
	else:
		var took := _grid_take(id, left)
		_add_count(inventory, id, -took)
		left -= took
	if left > 0 and storage.get(id, 0) > 0:
		var take := mini(storage[id], left)
		_add_count(storage, id, -take)
		left -= take
	for slot in ["armor", "weapon"]:
		if left > 0 and get(slot) == id:
			set(slot, "")
			_add_count(inventory, id, -1)
			left -= 1
	_refresh_collect_objectives()
	changed.emit()
	return true


## Quantos dá para vender sem tirar o que está equipado.
func spare_count(id: String) -> int:
	return item_count(id) - (1 if weapon == id else 0) - (1 if armor == id else 0)


func equip(id: String) -> String:
	var data := Data.item(id)
	var slot := "weapon" if data.get("tipo") == "arma" else "armor" if data.get("tipo") == "armadura" else ""
	if slot == "" or spare_count(id) <= 0:
		return "Não dá para equipar isso."
	if _grid_take(id, 1) == 0:
		_add_count(storage, id, -1)
		_add_count(inventory, id, 1)
	var old: String = get(slot)
	set(slot, id)
	var note := ""
	if old != "" and _grid_insert(old, 1) == 0:
		_add_count(inventory, old, -1)
		_add_count(storage, old, 1)
		note = " %s foi para o baú." % Data.item(old).nome
	changed.emit()
	return "Equipou %s.%s" % [data.nome, note]


func unequip(slot: String) -> String:
	var id: String = get(slot)
	if id == "":
		return ""
	if _grid_insert(id, 1) == 0:
		return "Não há espaço na bolsa para guardar %s." % Data.item(id).nome
	set(slot, "")
	changed.emit()
	return "Guardou %s na bolsa." % Data.item(id).nome


func defense() -> int:
	return int(Data.item(armor).get("defesa", 0)) if armor != "" else 0


func move_entry(entry: Dictionary, cell: Vector2i, rotated: bool) -> bool:
	if not fits(entry.id, cell, rotated, entry):
		return false
	entry.x = cell.x
	entry.y = cell.y
	entry.r = rotated
	changed.emit()
	return true


## Junta dois itens: receita (ex.: erva + erva = poção) ou duas pilhas do mesmo item.
func combine(a: Dictionary, b: Dictionary) -> String:
	if a == b:
		return ""
	var result := recipe_for(a.id, b.id)
	if result != "":
		for entry in [a, b]:
			entry.n = int(entry.n) - 1
			_add_count(inventory, entry.id, -1)
			if entry.n <= 0:
				grid.erase(entry)
		add_item(result, 1, false)
		return "Combinou e criou %s!" % Data.item(result).nome
	if a.id == b.id and stack_max(a.id) > 1:
		var moved := mini(stack_max(b.id) - int(b.n), int(a.n))
		if moved <= 0:
			return "Essa pilha já está cheia."
		b.n = int(b.n) + moved
		a.n = int(a.n) - moved
		if a.n <= 0:
			grid.erase(a)
		changed.emit()
		return "Juntou as pilhas."
	return "Esses itens não combinam."


func recipe_for(a: String, b: String) -> String:
	for r in Data.recipes:
		if (r.a == a and r.b == b) or (r.a == b and r.b == a):
			return r.r
	return ""


## Reorganiza a grade: maiores primeiro, pilhas completas.
func organize() -> void:
	var counts := {}
	for entry in grid:
		counts[entry.id] = counts.get(entry.id, 0) + int(entry.n)
	grid = []
	var ids := counts.keys()
	ids.sort_custom(func(x, y):
		var ax := item_size(x).x * item_size(x).y
		var ay := item_size(y).x * item_size(y).y
		return ax > ay if ax != ay else Data.item(x).nome < Data.item(y).nome)
	for id in ids:
		var placed := _grid_insert(id, counts[id])
		if placed < counts[id]:
			_add_count(inventory, id, placed - counts[id])
			_add_count(storage, id, counts[id] - placed)
	changed.emit()


## O baú só abre em lugares seguros: cidades e dentro das casas.
func storage_open() -> bool:
	var region := Data.region_of(map_id)
	if region != "" and region != map_id:
		return true
	return Data.world.get("regioes", {}).get(region, {}).get("tipo", "") == "cidade"


func store_entry(entry: Dictionary) -> void:
	_add_count(storage, entry.id, int(entry.n))
	_add_count(inventory, entry.id, -int(entry.n))
	grid.erase(entry)
	changed.emit()


func take_from_storage(id: String) -> String:
	var placed := _grid_insert(id, storage.get(id, 0))
	if placed == 0:
		return "Não há espaço na bolsa."
	_add_count(storage, id, -placed)
	_add_count(inventory, id, placed)
	changed.emit()
	return "Pegou %d %s." % [placed, Data.item(id).nome]


## Saves antigos (e o começo do jogo) não têm grade: arruma tudo na bolsa e manda o resto ao baú.
func _rebuild_grid() -> void:
	grid = []
	var ids := inventory.keys().filter(func(id): return not is_key_item(id))
	ids.sort_custom(func(x, y): return item_size(x).x * item_size(x).y > item_size(y).x * item_size(y).y)
	for id in ids:
		var equipped := (1 if weapon == id else 0) + (1 if armor == id else 0)
		var loose: int = inventory[id] - equipped
		var placed := _grid_insert(id, loose)
		if placed < loose:
			_add_count(inventory, id, placed - loose)
			_add_count(storage, id, loose - placed)


func use_item(id: String) -> String:
	var data := Data.item(id)
	match data.get("tipo", ""):
		"consumivel":
			var cures: bool = data.get("cura_status", false)
			if hp >= max_hp() and not cures:
				return "Sua vida já está cheia."
			if item_cooldown > 0.0:
				return "Espere um pouco para usar outro item."
			item_cooldown = ITEM_COOLDOWN
			Som.sfx("pocao", -4.0)
			remove_item(id)
			heal(roundi(int(data.get("cura", 0)) * class_bonus("cura", 1.0)))
			if cures:
				status_cured.emit()
			return "Você usou %s." % data.nome
		"arma", "armadura":
			return equip(id)
	return "Não dá para usar isso agora."


func money(currency: String) -> int:
	return wallet.get(currency, 0)


func add_money(currency: String, amount: int, announce := false) -> void:
	wallet[currency] = money(currency) + amount
	if announce:
		toast.emit("+%d %s" % [amount, Data.currency_name(currency)])
	changed.emit()


func spend(currency: String, amount: int) -> bool:
	if money(currency) < amount:
		return false
	wallet[currency] = money(currency) - amount
	changed.emit()
	return true


## Converte moedas pelo valor base de cada uma, cobrando a taxa do cambista.
func exchange_quote(from: String, to: String, amount: int) -> int:
	var rate_from := float(Data.currencies[from].valor)
	var rate_to := float(Data.currencies[to].valor)
	var tax := float(Data.currencies.get("_taxa", 0.1))
	return int(floor(amount * rate_from / rate_to * (1.0 - tax)))


func exchange(from: String, to: String, amount: int) -> int:
	var received := exchange_quote(from, to, amount)
	if received <= 0 or not spend(from, amount):
		return 0
	add_money(to, received)
	return received


# ---------- Missões ----------

func quest_state(id: String) -> String:
	return quests.get(id, {}).get("estado", "nao_iniciada")


func start_quest(id: String) -> void:
	if quest_state(id) != "nao_iniciada" or not Data.quests.has(id):
		return
	var objectives: Array = Data.quests[id].get("objetivos", [])
	var progress := []
	progress.resize(objectives.size())
	progress.fill(0)
	quests[id] = {"estado": "ativa", "progresso": progress}
	toast.emit("Nova missão: " + Data.quests[id].titulo)
	_refresh_collect_objectives()
	_check_ready(id)
	changed.emit()


## Registra um evento do jogo ("matar", "falar", "ir", "flag") para avançar missões.
func notify(kind: String, target: String, amount := 1) -> void:
	for id in quests.keys():
		if quests[id].estado != "ativa":
			continue
		var objectives: Array = Data.quests[id].objetivos
		for i in objectives.size():
			var obj: Dictionary = objectives[i]
			if obj.tipo == kind and obj.get("alvo", "") == target:
				var needed := int(obj.get("qtd", 1))
				quests[id].progresso[i] = mini(quests[id].progresso[i] + amount, needed)
		_check_ready(id)


func _refresh_collect_objectives() -> void:
	for id in quests.keys():
		if quests[id].estado in ["concluida", "falhou"]:
			continue
		var objectives: Array = Data.quests[id].objetivos
		for i in objectives.size():
			if objectives[i].tipo == "coletar":
				quests[id].progresso[i] = mini(item_count(objectives[i].alvo), int(objectives[i].get("qtd", 1)))
		if quests[id].estado == "pronta" and not _objectives_done(id):
			quests[id].estado = "ativa"
		_check_ready(id)


func _objectives_done(id: String) -> bool:
	var objectives: Array = Data.quests[id].objetivos
	for i in objectives.size():
		if quests[id].progresso[i] < int(objectives[i].get("qtd", 1)):
			return false
	return true


func _check_ready(id: String) -> void:
	if quests[id].estado != "ativa" or not _objectives_done(id):
		return
	if Data.quests[id].has("entregar_a"):
		quests[id].estado = "pronta"
		toast.emit("Missão pronta: fale com " + Data.npcs.get(Data.quests[id].entregar_a, {}).get("nome", "?"))
		changed.emit()
	else:
		complete_quest(id)


func complete_quest(id: String) -> void:
	if quest_state(id) in ["concluida", "falhou"] or not Data.quests.has(id):
		return
	var quest: Dictionary = Data.quests[id]
	if not quests.has(id):
		start_quest(id)
		if quest_state(id) == "concluida":
			return
	# Itens coletados são entregues ao concluir.
	for obj in quest.objetivos:
		if obj.tipo == "coletar" and obj.get("consumir", true):
			remove_item(obj.alvo, int(obj.get("qtd", 1)))
	var rank_before := rank()
	quests[id].estado = "concluida"
	var details := []
	# Ajudar as pessoas aumenta a honra.
	var before := honra
	add_honor(int(quest.get("honra", 6 if quest.get("tipo") == "secundaria" else 2)), false)
	if honra != before:
		details.append("Honra %+d" % (honra - before))
	var reward: Dictionary = quest.get("recompensa", {})
	for currency in reward.get("moedas", {}):
		add_money(currency, int(reward.moedas[currency]))
		details.append("+%d %s" % [int(reward.moedas[currency]), Data.currency_name(currency)])
	for item_id in reward.get("itens", {}):
		add_item(item_id, int(reward.itens[item_id]), false)
		details.append("+%d %s" % [int(reward.itens[item_id]), Data.item(item_id).nome])
	for flag in reward.get("flags", []):
		set_flag(flag)
	if reward.has("xp"):
		details.append("+%d EXP" % int(reward.xp))
	quest_finished.emit(id, true, details)
	if reward.has("xp"):
		add_xp(int(reward.xp))
	if quest.has("proxima"):
		start_quest(quest.proxima)
	_check_rank(rank_before)
	changed.emit()


## Missão perdida (escolha desonesta, prazo, alguém que não foi salvo). Não volta mais.
func fail_quest(id: String, reason := "") -> void:
	if not Data.quests.has(id) or quest_state(id) in ["concluida", "falhou"]:
		return
	if not quests.has(id):
		start_quest(id)
	quests[id].estado = "falhou"
	var details := []
	if reason != "":
		details.append(reason)
	var penalty := int(Data.quests[id].get("honra_falha", 0))
	if penalty != 0:
		var before := honra
		add_honor(-absi(penalty), false)
		if honra != before:
			details.append("Honra %+d" % (honra - before))
	quest_finished.emit(id, false, details)
	changed.emit()


func _check_rank(before: String) -> void:
	var now := rank()
	if now != before:
		toast.emit("Nova hierarquia: %s!" % now)
		rank_changed.emit(now)


## Missão principal ativa para o rastreador do HUD.
func tracked_quest() -> String:
	for id in quests.keys():
		if not quests[id].estado in ["concluida", "falhou"] and Data.quests[id].get("tipo") == "principal":
			return id
	for id in quests.keys():
		if not quests[id].estado in ["concluida", "falhou"]:
			return id
	return ""


func objective_text(id: String) -> String:
	var quest: Dictionary = Data.quests[id]
	if quests[id].estado == "pronta":
		return "Fale com " + Data.npcs.get(quest.entregar_a, {}).get("nome", "?")
	var objectives: Array = quest.objetivos
	for i in objectives.size():
		var needed := int(objectives[i].get("qtd", 1))
		if quests[id].progresso[i] < needed:
			var text: String = objectives[i].texto
			return text + (" (%d/%d)" % [quests[id].progresso[i], needed] if needed > 1 else "")
	return ""


# ---------- Aliados ----------

func add_ally(id: String) -> void:
	if not id in allies:
		allies.append(id)
		toast.emit("%s entrou no grupo!" % Data.npcs.get(id, {}).get("nome", id))
		changed.emit()


func remove_ally(id: String) -> void:
	allies.erase(id)
	changed.emit()


# ---------- Mapa geral ----------

func visit(map: String) -> void:
	var region := Data.region_of(map)
	if region != "" and not visited.has(region):
		visited[region] = true
		changed.emit()


## Saves antigos não guardavam as regiões visitadas: revela tudo dos capítulos anteriores ao atual.
func _guess_visited() -> void:
	var regions: Dictionary = Data.world.get("regioes", {})
	var here := Data.region_of(map_id)
	var chapter := int(regions.get(here, {}).get("ordem", 1))
	for id in regions:
		if int(regions[id].ordem) < chapter:
			visited[id] = true
	if here != "":
		visited[here] = true


# ---------- Salvamento ----------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"flags": flags, "quests": quests, "inventory": inventory, "wallet": wallet,
		"weapon": weapon, "level": level, "xp": xp, "hp": hp, "allies": allies,
		"map_id": map_id, "spawn_id": spawn_id, "quick_item": quick_item,
		"honra": honra, "classe": classe, "visitados": visited,
		"armadura": armor, "grade": grid, "bau": storage, "bolsa": bag_level,
		"furia": fury, "montarias": mounts, "montaria": mount, "balanco": BALANCE,
	}))


func load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	flags = data.flags
	quests = data.quests
	inventory = data.inventory
	wallet = data.wallet
	weapon = data.weapon
	level = int(data.level)
	xp = int(data.xp)
	# Saves de antes do rebalanceamento 2: converte o nível para a escala nova.
	if int(data.get("balanco", 1)) < BALANCE:
		level = mini(MAX_LEVEL, old_level_to_new(level))
		xp = 0
	hp = int(data.hp)
	allies = data.allies
	map_id = data.map_id
	spawn_id = data.spawn_id
	quick_item = data.get("quick_item", "pocao_pequena")
	honra = int(data.get("honra", 50))
	classe = data.get("classe", "")
	visited = data.get("visitados", {})
	if not data.has("visitados"):
		_guess_visited()
	armor = data.get("armadura", "")
	storage = data.get("bau", {})
	bag_level = int(data.get("bolsa", 0))
	fury = float(data.get("furia", 0.0))
	mounts = data.get("montarias", [])
	mount = data.get("montaria", "")
	# Saves antigos: quem já venceu a Rainha já merece o golpe especial.
	if flags.get("chefe_rainha", false):
		flags["golpe_especial"] = true
	# JSON devolve números como float; normaliza contadores.
	for id in inventory:
		inventory[id] = int(inventory[id])
	for id in storage:
		storage[id] = int(storage[id])
	if data.has("grade"):
		grid = data.grade
		for entry in grid:
			entry.x = int(entry.x)
			entry.y = int(entry.y)
			entry.n = int(entry.n)
	else:
		_rebuild_grid()
	for c in wallet:
		wallet[c] = int(wallet[c])
	for id in quests:
		var progress: Array = quests[id].progresso
		for i in progress.size():
			progress[i] = int(progress[i])
	changed.emit()
	if int(data.get("balanco", 1)) < BALANCE:
		hp = max_hp()
	return true
