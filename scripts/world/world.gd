extends Node2D
## Controla o jogo: carrega mapas, cria NPCs e inimigos, roda diálogos, cutscenes e menus.

const TILE := 16
const INTERACT_RANGE := 28.0
const RESPAWN_TIME := 10.0

var player: Player
var hud: Hud
var dialog: DialogBox
var camera: ShakeCamera
var map_data := {}
var map_id := ""

var _level: Node2D
var _entities: Node2D
var _ui: CanvasLayer
var _fade: ColorRect
var _npcs := {}
var _pickups := {}
var _boss: Boss
var _running_triggers := {}
var _save_queued := false
## Só salva depois que o jogo começou de fato (nunca na tela de título).
var _playing := false
var _refresh_queued := false
var _busy := 0
var _map_serial := 0
var _changing := false
## Telas de missão concluída/falhou esperando o jogador ficar livre (fim do diálogo, da cena).
var _quest_screens: Array = []
var _showing_quest := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_level = Node2D.new()
	_level.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_level)
	add_to_group("mundo")
	camera = ShakeCamera.new()
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.open_inventory.connect(func(): _open_player_menu(InventoryPanel.new()))
	hud.open_quests.connect(func(): _open_player_menu(QuestLog.new()))
	hud.open_pause.connect(_open_pause)
	hud.open_map.connect(_open_map)
	hud.minimap.source = self
	_ui = CanvasLayer.new()
	_ui.layer = 5
	_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui)
	dialog = DialogBox.new()
	_ui.add_child(dialog)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)

	GameState.changed.connect(_queue_refresh)
	GameState.changed.connect(_queue_save)
	GameState.leveled_up.connect(_level_up_effect)
	GameState.quest_finished.connect(func(id, success, details): _quest_screens.append([id, success, details]))
	hud.visible = false
	var title_layer := CanvasLayer.new()
	title_layer.layer = 20
	add_child(title_layer)
	var title := TitleScreen.new()
	title_layer.add_child(title)
	var new_game: bool = await title.chosen
	title_layer.queue_free()
	if new_game or not GameState.load_game():
		GameState.new_game()
	hud.visible = true
	await load_map(GameState.map_id, GameState.spawn_id)
	_playing = true
	await _fade_to(0.0)


func _process(_delta: float) -> void:
	if is_instance_valid(player) and _busy == 0:
		camera.global_position = player.global_position
	if not _quest_screens.is_empty() and _busy == 0 and not _changing and not _showing_quest and _playing \
			and is_instance_valid(player) and player.controllable:
		_show_quest_screen(_quest_screens.pop_front())
	if Input.is_action_just_pressed("inventory"):
		_open_player_menu(InventoryPanel.new())
	if Input.is_action_just_pressed("quests"):
		_open_player_menu(QuestLog.new())
	if Input.is_action_just_pressed("pause"):
		_open_pause()


# ---------- Mapas ----------

func tile_pos(cell) -> Vector2:
	return Vector2(cell[0], cell[1]) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


## Montar só ao ar livre: nada de casas, cavernas e masmorras.
func mount_allowed() -> bool:
	if map_data.get("interior", false) or map_data.get("sem_montaria", false):
		return false
	var walls := 0
	var total := 0
	for row in map_data.get("layout", []):
		total += row.length()
		walls += row.count("X") + row.count("c") + row.count("w") + row.count("f")
	return total == 0 or walls < total * 0.3


func change_map(id: String, spawn: String) -> void:
	if _changing:
		return
	_changing = true
	_busy += 1
	await _fade_to(1.0)
	await load_map(id, spawn)
	_busy -= 1
	# Volta os botões (ao renascer eles tinham sumido junto com a tela de derrota).
	hud.set_controls_visible(_busy == 0)
	await _fade_to(0.0)
	_changing = false


func load_map(id: String, spawn: String) -> void:
	_map_serial += 1
	for child in _level.get_children():
		_level.remove_child(child)
		child.queue_free()
	_npcs.clear()
	_pickups.clear()
	hud.hide_boss()
	_boss = null
	map_id = id
	map_data = Data.map(id)
	GameState.map_id = id
	GameState.spawn_id = spawn
	GameState.visit(id)

	var tiles := TileLayer.new()
	tiles.rows = map_data.layout
	tiles.map_id = id
	_level.add_child(tiles)
	hud.minimap.set_rows(map_data.layout)
	_entities = Node2D.new()
	_entities.y_sort_enabled = true
	_level.add_child(_entities)
	# Árvores altas entram no y-sort: o Ifrit passa por trás da copa.
	for tree in tiles.tall_sprites():
		_entities.add_child(tree)

	# Mapas menores que a tela ficam centralizados.
	var size := tiles.map_size() * TILE
	var view := get_viewport_rect().size
	var pad := Vector2(maxf(0.0, (view.x - size.x) / 2.0), maxf(0.0, (view.y - size.y) / 2.0))
	camera.limit_left = int(-pad.x)
	camera.limit_top = int(-pad.y)
	camera.limit_right = int(size.x + pad.x)
	camera.limit_bottom = int(size.y + pad.y)

	player = Player.new()
	player.position = tile_pos(map_data.spawns.get(spawn, map_data.spawns.values()[0]))
	player.joystick = hud.joystick
	hud.bind_player(player)
	player.died.connect(_on_player_died)
	player.interact_requested.connect(_on_interact)
	_entities.add_child(player)
	if GameState.riding and GameState.mount != "" and mount_allowed():
		player.set_mounted(true, false)
	else:
		GameState.riding = false
	camera.global_position = player.global_position
	camera.reset_smoothing()
	_spawn_allies()

	_refresh_conditional()
	for i in map_data.get("baus", []).size():
		var entry: Dictionary = map_data.baus[i]
		var chest := Prop.new()
		chest.kind = "bau"
		chest.data = entry
		chest.flag = "bau_%s_%d" % [id, i]
		chest.position = tile_pos(entry.pos)
		_entities.add_child(chest)
	for entry in map_data.get("placas", []):
		var sign_prop := Prop.new()
		sign_prop.kind = "placa"
		sign_prop.data = entry
		sign_prop.position = tile_pos(entry.pos)
		_entities.add_child(sign_prop)
	for i in map_data.get("empurraveis", []).size():
		var entry: Dictionary = map_data.empurraveis[i]
		var rock := Pushable.new()
		rock.flag = "pedra_%s_%d" % [id, i]
		var saved = GameState.flags.get(rock.flag)
		rock.cell = Vector2i(int(saved[0]), int(saved[1])) if saved is Array else Vector2i(int(entry.pos[0]), int(entry.pos[1]))
		_entities.add_child(rock)
	for zone in map_data.get("inimigos", []):
		if GameState.check(zone.get("se")):
			for n in int(zone.get("qtd", 1)):
				_spawn_enemy_in_zone(zone)
	if map_data.has("chefe"):
		_spawn_boss(map_data.chefe)
	for warp in map_data.get("saidas", []):
		_make_area(warp.area, _on_warp.bind(warp))
	for trigger in map_data.get("gatilhos", []):
		_make_area(trigger.area, _on_trigger.bind(trigger))

	hud.currency = map_data.get("moeda", "brasas")
	hud.refresh()
	hud.show_map_name(map_data.nome)
	Som.music("chefe" if is_instance_valid(_boss) else Som.music_for_map(id, map_data))
	GameState.notify("ir", id)
	GameState.save_game()
	await get_tree().physics_frame


## Texto que sobe e some no mundo (EXP ganha, dano, etc.).
func popup_text(at: Vector2, text: String, color := Color.WHITE, size := 8) -> void:
	if not is_instance_valid(_entities):
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.z_index = 50
	label.position = at - Vector2(30, 0)
	label.custom_minimum_size.x = 60
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "position:y", at.y - 18, 0.9).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tween.tween_callback(label.queue_free)


func _level_up_effect(new_level: int) -> void:
	if not is_instance_valid(player):
		return
	var fx := LevelUpEffect.new()
	player.add_child(fx)
	popup_text(player.global_position + Vector2(0, -26), "NÍVEL %d!" % new_level, Color(1, 0.85, 0.3), 12)


## Salva sempre que o progresso muda (missão, item, moeda), não só ao trocar de mapa.
func _queue_save() -> void:
	if _playing and not _save_queued:
		_save_queued = true
		_save_now.call_deferred()


func _save_now() -> void:
	_save_queued = false
	if _playing:
		GameState.save_game()


func _notification(what: int) -> void:
	# Celular: o app pode ser fechado a qualquer momento depois de ir para o fundo.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_now()
	# Botão "voltar" do Android abre a pausa em vez de fechar o jogo.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_open_pause()
	# Ao voltar para o app, o jogo espera pausado.
	if what == NOTIFICATION_APPLICATION_RESUMED and OS.has_feature("mobile"):
		_open_pause()


func _queue_refresh() -> void:
	if not _refresh_queued and is_instance_valid(_entities):
		_refresh_queued = true
		_refresh_conditional.call_deferred()


## Mostra ou esconde NPCs e coletáveis cuja condição ("se") mudou, sem precisar sair do mapa.
func _refresh_conditional() -> void:
	_refresh_queued = false
	if not is_instance_valid(_entities):
		return
	for entry in map_data.get("npcs", []):
		var visible_now := GameState.check(entry.get("se"))
		if visible_now and not _npcs.has(entry.id):
			_spawn_npc(entry.id, tile_pos(entry.pos), entry.get("vagar", false))
		elif not visible_now and _npcs.has(entry.id) and entry.has("se") and _busy == 0:
			_npcs[entry.id].queue_free()
			_npcs.erase(entry.id)
	for i in map_data.get("coletaveis", []).size():
		var entry: Dictionary = map_data.coletaveis[i]
		var flag := "coleta_%s_%d" % [map_id, i]
		var should_show := not GameState.has_flag(flag) and GameState.check(entry.get("se"))
		if should_show and not is_instance_valid(_pickups.get(flag)):
			var pickup := Pickup.new()
			pickup.item_id = entry.item
			pickup.flag = flag
			pickup.texture = load(Data.item(entry.item).get("sprite", "res://assets/saco.png"))
			pickup.position = tile_pos(entry.pos)
			_entities.add_child(pickup)
			_pickups[flag] = pickup
		elif not should_show and is_instance_valid(_pickups.get(flag)) and not GameState.has_flag(flag):
			_pickups[flag].queue_free()
			_pickups.erase(flag)


func _make_area(rect: Array, callback: Callable) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(rect[2], rect[3]) * TILE
	shape.shape = box
	area.position = Vector2(rect[0], rect[1]) * TILE + box.size / 2.0
	area.add_child(shape)
	area.body_entered.connect(func(body):
		if body is Player:
			callback.call())
	_level.add_child(area)


func _on_warp(warp: Dictionary) -> void:
	if _busy > 0 or _changing:
		return
	if not GameState.check(warp.get("se")):
		if warp.has("bloqueado"):
			await say(warp.bloqueado.get("s", ""), warp.bloqueado.t)
			# Empurra o jogador para fora da saída.
			player.position -= player.facing * 12.0
		return
	if GameState.level < int(warp.get("nivel", 0)):
		await say("", "Os inimigos daqui em diante são perigosos demais. Volte quando chegar ao nível %d." % int(warp.nivel))
		player.position -= player.facing * 12.0
		return
	Som.sfx("porta", -6.0)
	change_map(warp.mapa, warp.spawn)


func _on_trigger(trigger: Dictionary) -> void:
	var flag := "gatilho_%s_%s" % [map_id, trigger.get("id", "")]
	if GameState.has_flag(flag) or not GameState.check(trigger.get("se")):
		return
	# Com o chefe já na sala, a cena de aparição não roda de novo (era ela que invocava outro chefe).
	if trigger.has("cutscene") and is_instance_valid(_boss):
		return
	if _running_triggers.has(flag):
		return
	if trigger.get("uma_vez", true):
		GameState.set_flag(flag)
	# Espera a transição de mapa terminar antes de começar a cena.
	while _changing:
		await get_tree().process_frame
	_running_triggers[flag] = true
	if trigger.has("cutscene"):
		await run_cutscene(trigger.cutscene)
	elif trigger.has("dialogo"):
		await run_dialog(trigger.dialogo)
	_running_triggers.erase(flag)


# ---------- Personagens ----------

func _spawn_npc(id: String, pos: Vector2, wander := false) -> Npc:
	var npc := Npc.new()
	npc.npc_id = id
	npc.data = Data.npcs[id]
	npc.wander = wander
	npc.position = pos
	_entities.add_child(npc)
	_npcs[id] = npc
	return npc


func _spawn_allies() -> void:
	var slot := 0
	for id in GameState.allies:
		var ally := Ally.new()
		ally.npc_id = id
		ally.data = Data.npcs[id]
		ally.player = player
		ally.slot = slot
		ally.position = player.position + Vector2(-12 + slot * 24, 14)
		_entities.add_child(ally)
		slot += 1


func _spawn_enemy_in_zone(zone: Dictionary) -> void:
	var rect: Array = zone.area
	var tiles: TileLayer = _level.get_child(0)
	for attempt in 30:
		var cell := Vector2i(randi_range(rect[0], rect[0] + rect[2] - 1), randi_range(rect[1], rect[1] + rect[3] - 1))
		var pos := tile_pos([cell.x, cell.y])
		if not tiles.is_solid(cell) and pos.distance_to(player.position) > 64:
			spawn_enemy(_zone_type(zone), pos, zone)
			return


## Zonas "dinamico" (Cânion das Feras, arena): o tipo de fera acompanha o nível do Ifrit.
const LEVEL_TABLE := [[1, "escorpiao"], [6, "cobra"], [10, "escorpiao_negro"], [18, "hiena"], [20, "sapo"], [23, "serpentinha"],
	[25, "caranguejo"], [28, "pirata"], [33, "lobo_metal"], [41, "mumia"], [44, "escorpiao_cristal"], [49, "soldado"], [59, "cavaleiro"]]


func _zone_type(zone: Dictionary) -> String:
	if zone.tipo != "dinamico":
		return zone.tipo
	var options := []
	for entry in LEVEL_TABLE:
		if entry[0] <= GameState.level + 3 and entry[0] >= GameState.level - 10:
			options.append(entry[1])
	if options.is_empty():
		options = [LEVEL_TABLE.back()[1]]
	return options.pick_random()


func spawn_enemy(type_id: String, pos: Vector2, zone := {}) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(type_id)
	enemy.position = pos
	enemy.target = player
	enemy.died.connect(_on_enemy_died.bind(zone))
	_entities.add_child(enemy)
	return enemy


func _spawn_boss(entry: Dictionary) -> void:
	if GameState.has_flag(entry.flag) or not GameState.check(entry.get("se")):
		return
	if is_instance_valid(_boss) and not _boss.is_queued_for_deletion():
		return
	var boss := Boss.new()
	_boss = boss
	boss.setup(entry.tipo)
	boss.position = tile_pos(entry.pos)
	boss.target = player
	boss.died.connect(_on_boss_died.bind(entry))
	boss.hp_changed.connect(hud.update_boss)
	boss.set_meta("inicio", Time.get_ticks_msec())
	# Golpe traiçoeiro (escolha desonesta antes da luta): o chefe começa ferido.
	if GameState.has_flag("chefe_traido_" + map_id):
		boss.hp = int(boss.hp * 0.8)
	boss.summon.connect(func(type_id, at): spawn_enemy(type_id, at))
	_entities.add_child(boss)
	hud.show_boss(boss.data.nome, boss.hp, boss.max_hp)
	Som.music("chefe", 0.6)


func _on_enemy_died(enemy: Enemy, zone: Dictionary) -> void:
	if enemy.data.get("treino", false):
		GameState.notify("matar", enemy.type_id)
		popup_text(enemy.global_position + Vector2(0, -18), "Quebrou!", Color(0.9, 0.8, 0.5))
	else:
		_drop_loot(enemy)
	GameState.add_fury(GameState.FURY_PER_KILL)
	if zone.is_empty():
		return
	var serial := _map_serial
	await get_tree().create_timer(float(zone.get("renascer", RESPAWN_TIME)), false).timeout
	if serial == _map_serial:
		_spawn_enemy_in_zone(zone)


func _on_boss_died(boss: Enemy, entry: Dictionary) -> void:
	var info: Dictionary = boss.data
	var gained := GameState.xp_for_kill(int(info.get("xp", 1)), int(info.get("nivel", 1)))
	var seconds := int((Time.get_ticks_msec() - int(boss.get_meta("inicio", Time.get_ticks_msec()))) / 1000.0)
	_drop_loot(boss)
	GameState.set_flag(entry.flag)
	Som.music(Som.music_for_map(map_id, map_data), 2.5)
	hud.hide_boss()
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		if enemy != boss:
			enemy.queue_free()
	# Câmera lenta no golpe final, a explosão do chefe e depois a tela de vitória.
	var fx := BossDeathFx.new()
	fx.texture = boss._sprite.texture
	fx.sprite_scale = boss._sprite.scale.x
	fx.flip = boss._sprite.flip_h
	fx.position = boss.position
	_entities.add_child(fx)
	_set_busy(true)
	camera.global_position = boss.global_position.lerp(player.global_position, 0.3)
	var normal_speed := Engine.time_scale
	Engine.time_scale = normal_speed * 0.25
	await get_tree().create_timer(0.2, true, false, true).timeout
	Engine.time_scale = normal_speed
	await fx.finished
	var details := ["Tempo de luta  %d:%02d" % [seconds / 60, seconds % 60]]
	var rewards := []
	if gained > 0:
		rewards.append("+%d EXP" % gained)
	for item_id in info.get("garantidos", {}):
		rewards.append(Data.item(item_id).nome)
	if not rewards.is_empty():
		details.append("  ·  ".join(rewards))
	await hud.show_banner(Banner.Kind.BOSS_DEFEATED, "CHEFE DERROTADO", info.nome, details)
	_set_busy(false)
	if entry.has("cutscene"):
		await get_tree().create_timer(0.6, false).timeout
		await run_cutscene(entry.cutscene)


## Desafio da arena (Campo de Treino): três ondas de feras do nível do Ifrit dentro do cercado.
var _arena_running := false


func _arena_challenge() -> void:
	if _arena_running or not map_data.has("arena"):
		return
	_arena_running = true
	var serial := _map_serial
	var rect: Array = map_data.arena
	var round_number := int(GameState.flags.get("arena_rodadas", 0)) + 1
	for wave in 3:
		hud.toast("Onda %d de 3!" % (wave + 1))
		await get_tree().create_timer(1.2, false).timeout
		if serial != _map_serial:
			_arena_running = false
			return
		var spawned: Array = []
		for i in 2 + wave + mini(round_number - 1, 3):
			var cell := Vector2i(randi_range(rect[0], rect[0] + rect[2] - 1), randi_range(rect[1], rect[1] + rect[3] - 1))
			var enemy := spawn_enemy(_zone_type({"tipo": "dinamico"}), tile_pos([cell.x, cell.y]))
			enemy.data = enemy.data.duplicate()
			enemy.data["raio_aggro"] = 400
			spawned.append(enemy)
		while spawned.any(func(e): return is_instance_valid(e) and e.hp > 0):
			await get_tree().create_timer(0.3, false).timeout
			if serial != _map_serial or GameState.hp <= 0:
				_arena_running = false
				return
	_arena_running = false
	GameState.set_flag("arena_rodadas", round_number)
	GameState.set_flag("arena_vencida")
	var prize := 20 + 15 * GameState.level
	var xp := 10 + 6 * GameState.level
	GameState.add_money("brasas", prize)
	GameState.add_xp(xp)
	_set_busy(true)
	await hud.show_banner(Banner.Kind.REWARD, "ARENA VENCIDA  ·  RODADA %d" % round_number, "Campeão do Campo",
		["+%d Brasas  ·  +%d EXP" % [prize, xp], "Fale com o Mestre Sadiq para um novo desafio."])
	_set_busy(false)


func _show_quest_screen(entry: Array) -> void:
	_showing_quest = true
	var quest: Dictionary = Data.quests.get(entry[0], {})
	var tipo := "MISSÃO PRINCIPAL" if quest.get("tipo") == "principal" else "MISSÃO"
	_set_busy(true)
	if entry[1]:
		await hud.show_banner(Banner.Kind.QUEST_DONE, tipo + " CONCLUÍDA", quest.get("titulo", ""), _pair_lines(entry[2]))
	else:
		await hud.show_banner(Banner.Kind.QUEST_FAILED, tipo + " FALHOU", quest.get("titulo", ""), _pair_lines(entry[2]))
	_set_busy(false)
	_showing_quest = false


## Junta recompensas de duas em duas para caber na tela.
func _pair_lines(lines: Array) -> Array:
	var out := []
	var i := 0
	while i < lines.size():
		out.append("  ·  ".join(lines.slice(i, i + 2)))
		i += 2
	return out.slice(0, 3)


func _drop_loot(enemy: Enemy) -> void:
	var data := enemy.data
	var gained := GameState.xp_for_kill(int(data.get("xp", 1)), int(data.get("nivel", 1)))
	popup_text(enemy.global_position + Vector2(0, -18), "+%d EXP" % gained, Color(0.55, 0.85, 1.0))
	GameState.add_xp(gained)
	GameState.notify("matar", enemy.type_id)
	var currency: String = map_data.get("moeda", "brasas")
	var range_values: Array = data.get("moedas", [0, 0])
	var amount := randi_range(int(range_values[0]), int(range_values[1]))
	var drops := []
	if amount > 0:
		var coin := Pickup.new()
		coin.currency = currency
		coin.amount = amount
		coin.texture = load(Data.currencies[currency].sprite)
		drops.append(coin)
	for item_id in data.get("drops", {}):
		if randf() < float(data.drops[item_id]):
			drops.append(_item_pickup(item_id, 1))
	# Chefes deixam itens garantidos.
	var guaranteed: Dictionary = data.get("garantidos", {})
	for item_id in guaranteed:
		drops.append(_item_pickup(item_id, int(guaranteed[item_id])))
	# Coração: mais chance quando o Ifrit está com pouca vida.
	var heart_chance := 0.12 + (0.18 if GameState.hp < GameState.max_hp() * 0.4 else 0.0)
	if not guaranteed.is_empty() or randf() < heart_chance:
		var heart := Pickup.new()
		heart.heal = 2 + GameState.max_hp() / 10
		heart.texture = preload("res://assets/coracao.png")
		drops.append(heart)
	for i in drops.size():
		var pickup: Pickup = drops[i]
		pickup.position = enemy.position
		# Espalha em leque para baixo do inimigo.
		pickup.toss = Vector2((i - (drops.size() - 1) / 2.0) * 12.0, 8.0 + randf() * 4.0)
		_entities.add_child.call_deferred(pickup)
		if pickup.rare:
			popup_text(enemy.global_position + Vector2(0, -28), Data.item(pickup.item_id).nome + "!", Color(1, 0.85, 0.3))


func _item_pickup(item_id: String, count: int) -> Pickup:
	var item := Pickup.new()
	item.item_id = item_id
	item.amount = count
	item.rare = Data.item(item_id).get("raro", false)
	item.texture = load(Data.item(item_id).get("sprite", "res://assets/saco.png"))
	return item


func _on_player_died() -> void:
	_busy += 1
	await get_tree().create_timer(0.8).timeout
	# Perde um pouco da moeda local ao cair.
	var currency: String = map_data.get("moeda", "brasas")
	var lost := GameState.money(currency) - int(GameState.money(currency) * 0.9)
	GameState.wallet[currency] = GameState.money(currency) - lost
	var back: Array = map_data.get("renascer", [map_id, GameState.spawn_id])
	var details := ["Voltando para %s" % Data.map(back[0]).get("nome", "")]
	if lost > 0:
		details.insert(0, "Perdeu %d %s" % [lost, Data.currency_name(currency)])
	await hud.show_banner(Banner.Kind.DEFEAT, "VOCÊ CAIU", "Levante-se, Ifrit", details)
	# Caiu na luta contra um chefe: a luta recomeça do zero (o chefe volta a dormir).
	if map_data.has("chefe") and not GameState.has_flag(map_data.chefe.flag):
		var wake = map_data.chefe.get("se", {})
		if wake is Dictionary and wake.has("flag"):
			GameState.flags.erase(wake.flag)
	GameState.hp = GameState.max_hp()
	_busy -= 1
	_changing = false
	await change_map(back[0], back[1])


# ---------- Interação, diálogos e ações ----------

func _on_interact() -> void:
	if _busy > 0 or get_tree().paused:
		return
	var probe := player.global_position + player.facing * 8.0
	var best: Node2D = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("npcs") + get_tree().get_nodes_in_group("interagiveis"):
		var distance: float = node.global_position.distance_to(probe)
		if distance < best_distance:
			best = node
			best_distance = distance
	if best is Npc:
		best.face(player.global_position - best.global_position)
		player.face(best.global_position - player.global_position)
		GameState.notify("falar", best.npc_id)
		var fala: Dictionary = best.current_dialog()
		if not fala.is_empty():
			await run_dialog(fala.dialogo)
	elif best is Prop:
		await _use_prop(best)
	else:
		_try_tame(probe)


## Domar: uma fera domável, cansada (pouca vida), aceita a isca e vira montaria.
func _try_tame(probe: Vector2) -> void:
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		if enemy is Boss or enemy.global_position.distance_to(probe) > INTERACT_RANGE + 6.0:
			continue
		var mount_id := Enemy.tame_mount(enemy.type_id)
		if mount_id == "":
			continue
		var info := Data.mount(mount_id)
		if mount_id in GameState.mounts:
			hud.toast("Você já domou um(a) %s." % info.nome)
			return
		if enemy.hp > enemy.max_hp * Enemy.TAME_HP:
			hud.toast("A fera ainda está brava. Canse-a em luta antes de domar.")
			return
		if GameState.item_count(info.isca) <= 0:
			hud.toast("Precisa de %s como isca." % Data.item(info.isca).nome)
			return
		GameState.remove_item(info.isca)
		popup_text(enemy.global_position + Vector2(0, -20), "♥", Color(1, 0.4, 0.5), 14)
		enemy.remove_from_group("inimigos")
		enemy.queue_free()
		GameState.add_mount(mount_id)
		await hud.show_banner(Banner.Kind.REWARD, "MONTARIA DOMADA", info.nome,
			["Toque em MONTAR ao ar livre para cavalgar.", "Montado você corre mais, mas não ataca."])
		return


func _use_prop(prop: Prop) -> void:
	if prop.kind == "placa":
		await say("", prop.data.texto)
		return
	if prop.is_open():
		await say("", "O baú está vazio.")
		return
	prop.open()
	var found := []
	for item_id in prop.data.get("itens", {}):
		GameState.add_item(item_id, int(prop.data.itens[item_id]), false)
		found.append("%s x%d" % [Data.item(item_id).nome, prop.data.itens[item_id]])
	for currency in prop.data.get("moedas", {}):
		GameState.add_money(currency, int(prop.data.moedas[currency]))
		found.append("%d %s" % [prop.data.moedas[currency], Data.currency_name(currency)])
	await say("", "Você encontrou: " + ", ".join(found) + ".")


func say(speaker: String, text: String) -> void:
	await run_dialog_data({"linhas": [{"s": speaker, "t": text}]})


func run_dialog(id: String) -> void:
	if not Data.dialogs.has(id):
		push_error("Diálogo não encontrado: " + id)
		return
	await run_dialog_data(Data.dialogs[id])


func run_dialog_data(data: Dictionary) -> void:
	_set_busy(true)
	# Esconde escolhas cuja condição não vale (ex.: pagar sem ter moedas).
	if data.has("escolhas"):
		data = data.duplicate()
		data.escolhas = data.escolhas.filter(func(c): return GameState.check(c.get("se")))
	var choice := await dialog.play(data)
	await run_actions(data.get("acoes", []))
	if not choice.is_empty():
		await run_actions(choice.get("acoes", []))
		if choice.has("ir"):
			await run_dialog(choice.ir)
	_set_busy(false)


func run_actions(actions: Array) -> void:
	for action in actions:
		var amount := int(action.get("qtd", 1))
		for key in action:
			var value = action[key]
			match key:
				"flag": GameState.set_flag(value)
				"remover_flag": GameState.flags.erase(value)
				"quest_iniciar": GameState.start_quest(value)
				"quest_concluir": GameState.complete_quest(value)
				"quest_falhar": GameState.fail_quest(value, str(action.get("motivo", "")))
				"segredo": GameState.find_secret(str(value))
				"dar_item": GameState.add_item(value, amount)
				"remover_item": GameState.remove_item(value, amount)
				"moeda": GameState.add_money(value, amount, true)
				"pagar": GameState.spend(value, amount)
				"xp": GameState.add_xp(int(value))
				"honra": GameState.add_honor(int(value))
				"classe": GameState.set_class(str(value))
				"aliado":
					GameState.add_ally(value)
					_respawn_allies()
				"remover_aliado":
					GameState.remove_ally(value)
					_respawn_allies()
				"curar":
					GameState.heal(GameState.max_hp())
					hud.toast("Vida recuperada!")
				"dormir": await _sleep()
				"loja":
					var shop := ShopPanel.new()
					shop.shop_id = value
					await _open_menu(shop)
				"cambio": await _open_menu(ExchangePanel.new())
				"cutscene": await run_cutscene(value)
				"sumir_npc":
					if _npcs.has(value):
						_npcs[value].queue_free()
						_npcs.erase(value)
				"invocar_chefe":
					if map_data.has("chefe"):
						_spawn_boss(map_data.chefe)
						if is_instance_valid(_boss):
							var info: Dictionary = _boss.data
							await hud.show_banner(Banner.Kind.BOSS_INTRO, "CHEFE  ·  NÍVEL %d" % int(info.get("nivel", 1)),
								info.nome, [info.get("lema", "Fique nas brechas da onda de choque.")])
				"dialogo": await run_dialog(value)
				"arena": _arena_challenge.call_deferred()
				"ir_mapa": await change_map(value[0], value[1])
				"salvar":
					GameState.save_game()
					hud.toast("Jogo salvo.")


func _respawn_allies() -> void:
	for node in _entities.get_children():
		if node is Ally:
			node.queue_free()
	_spawn_allies()


## Menus abertos pelo jogador (bolsa, missões) só abrem fora de cenas e diálogos.
func _open_player_menu(menu: Control) -> void:
	if _busy > 0 or _changing or not is_instance_valid(player) or GameState.hp <= 0:
		menu.free()
		return
	await _open_menu(menu)


func _open_pause() -> void:
	if not _playing or _busy > 0 or _changing or not is_instance_valid(player) or GameState.hp <= 0:
		return
	# Volta para a pausa depois de bolsa, missões, mapa e configurações; sai ao continuar.
	while true:
		var menu := PauseMenu.new()
		await _open_menu(menu)
		match menu.choice:
			"bolsa": await _open_menu(InventoryPanel.new())
			"missoes": await _open_menu(QuestLog.new())
			"mapa": await _open_map()
			"config": await _open_menu(SettingsPanel.new())
			"salvar":
				GameState.save_game()
				hud.toast("Jogo salvo.")
				return
			"titulo":
				GameState.save_game()
				get_tree().paused = false
				get_tree().reload_current_scene()
				return
			_:
				return


func _open_map() -> void:
	if not is_instance_valid(player) or _changing:
		return
	var panel := MapPanel.new()
	panel.source = self
	await _open_menu(panel)


func current_rows() -> Array:
	return map_data.get("layout", [])


## Posições (em tiles) do que aparece no mini mapa.
func minimap_markers() -> Dictionary:
	var out := {"npcs": [], "importantes": [], "inimigos": [], "saidas": []}
	if not is_instance_valid(player):
		return out
	out.jogador = player.global_position / TILE
	for id in _npcs:
		var npc = _npcs[id]
		if is_instance_valid(npc):
			(out.importantes if npc._marker.visible else out.npcs).append(npc.global_position / TILE)
	for enemy in get_tree().get_nodes_in_group("inimigos"):
		if enemy == _boss:
			out.chefe = enemy.global_position / TILE
		else:
			out.inimigos.append(enemy.global_position / TILE)
	for warp in map_data.get("saidas", []):
		var a: Array = warp.area
		out.saidas.append(Vector2(a[0] + a[2] / 2.0, a[1] + a[3] / 2.0))
	return out


func _open_menu(menu: Control) -> void:
	_set_busy(true)
	Som.ui("abrir")
	_ui.add_child(menu)
	await menu.closed
	Som.ui("fechar")
	menu.queue_free()
	_set_busy(false)


func _set_busy(value: bool) -> void:
	_busy += 1 if value else -1
	_busy = maxi(_busy, 0)
	get_tree().paused = _busy > 0
	hud.set_controls_visible(_busy == 0)
	if is_instance_valid(player):
		player.controllable = _busy == 0 and GameState.hp > 0


## Dormir na estalagem: a tela escurece como a noite, passa o sono e clareia num amanhecer.
func _sleep() -> void:
	_set_busy(true)
	Som.sfx("dormir")
	var night := Color(0.03, 0.04, 0.12, 0.0)
	_fade.color = night
	var zzz := Label.new()
	zzz.text = "z  Z  z"
	zzz.add_theme_font_size_override("font_size", 16)
	zzz.add_theme_color_override("font_color", Color(0.75, 0.8, 1.0))
	zzz.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zzz.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zzz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	zzz.modulate.a = 0.0
	_fade.add_child(zzz)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(zzz, "modulate:a", 1.0, 0.4)
	tween.tween_property(zzz, "position:y", -6.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(zzz, "modulate:a", 0.0, 0.4)
	await tween.finished
	GameState.heal(GameState.max_hp())
	# Amanhecer: do azul da noite para o laranja do sol, e o mundo aparece de novo.
	var dawn := create_tween()
	dawn.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	dawn.tween_property(_fade, "color", Color(1.0, 0.62, 0.3, 0.85), 0.8)
	dawn.tween_property(_fade, "color", Color(1.0, 0.9, 0.7, 0.0), 1.3).set_trans(Tween.TRANS_SINE)
	await dawn.finished
	zzz.queue_free()
	_fade.color = Color(0, 0, 0, 0)
	_set_busy(false)
	hud.toast("Bom dia! Vida recuperada.")


func _fade_to(alpha: float, duration := 0.35) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade, "color:a", alpha, duration)
	await tween.finished


# ---------- Cutscenes ----------

func _actor(id: String) -> Node2D:
	if id == "jogador":
		return player
	return _npcs.get(id)


func _walk(node: Node2D, target: Vector2, speed := 50.0) -> void:
	if node == null:
		return
	if node.has_method("face"):
		node.face(target - node.global_position)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(node, "global_position", target, maxf(node.global_position.distance_to(target) / speed, 0.05))
	await tween.finished


func run_cutscene(id: String) -> void:
	if not Data.cutscenes.has(id):
		push_error("Cutscene não encontrada: " + id)
		return
	_set_busy(true)
	for step in Data.cutscenes[id]:
		match step.cmd:
			"dialogo": await run_dialog(step.id)
			"fala": await say(step.get("s", ""), step.t)
			"mover":
				var who := _actor(step.quem)
				if step.get("esperar", true):
					await _walk(who, tile_pos(step.para), float(step.get("vel", 50)))
				else:
					_walk(who, tile_pos(step.para), float(step.get("vel", 50)))
			"virar":
				var who := _actor(step.quem)
				if who and who.has_method("face"):
					if step.para is String:
						# Vira para outro personagem; se ele não estiver no mapa, ignora o passo.
						var target: Node2D = _actor(step.para)
						if target:
							who.face(target.global_position - who.global_position)
					else:
						who.face(Vector2(step.para[0], step.para[1]))
			"esperar": await get_tree().create_timer(float(step.t), true).timeout
			"escurecer": await _fade_to(1.0, float(step.get("t", 0.5)))
			"clarear": await _fade_to(0.0, float(step.get("t", 0.5)))
			"titulo": await hud.show_title(step.t, step.get("sub", ""))
			"camera":
				var tween := create_tween()
				tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tween.tween_property(camera, "global_position", tile_pos(step.para), float(step.get("t", 1.0)))
				await tween.finished
			"tremer":
				for i in 8:
					camera.offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
					await get_tree().create_timer(0.04, true).timeout
				camera.offset = Vector2.ZERO
			"surgir":
				if _npcs.has(step.npc):
					_npcs[step.npc].global_position = tile_pos(step.pos)
				else:
					_spawn_npc(step.npc, tile_pos(step.pos))
			"sumir":
				if _npcs.has(step.npc):
					_npcs[step.npc].queue_free()
					_npcs.erase(step.npc)
			"acoes": await run_actions(step.acoes)
			"tela":
				# Tela cheia própria (finais, poema, créditos): um Control com o sinal `finished`.
				var screen: Control = load(step.script).new()
				_ui.add_child(screen)
				await screen.finished
				screen.queue_free()
			"mapa":
				_set_busy(false)
				await change_map(step.mapa, step.spawn)
				_set_busy(true)
	_set_busy(false)
