extends SceneTree
## Teste do áudio: título, mapas, chefe, efeitos e vinhetas. Roda com xvfb.

var errors := []

func _wait(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await process_frame

func _initialize() -> void:
	_run()

func _run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await _wait(1500)
	var som = root.get_node("Som")
	print("TITULO musica=", som._current, " tocando=", som._music[som._active].playing)
	var title = world.find_children("*", "TitleScreen", true, false)
	if title.size() > 0:
		title[0].chosen.emit(false)
	await _wait(2500)
	print("JOGO mapa=", world.map_id, " musica=", som._current)
	for m in ["areia_rubra", "dunas_rubras", "lar_areia_rubra_1", "porto_coral", "vale_ventos", "cidadela_sal", "mar_de_areia", "covil_escorpiao", "caverna_zazu"]:
		await world.load_map(m, root.get_node("Data").map(m).spawns.keys()[0])
		await _wait(300)
		print("MAPA ", m, " -> ", som._current, " ok=", som._music[som._active].stream != null)
	var gs = root.get_node("GameState")
	gs.flags.erase("chefe_rainha")
	gs.set_flag("rainha_desperta")
	await world.load_map("covil_escorpiao", root.get_node("Data").map("covil_escorpiao").spawns.keys()[0])
	await _wait(300)
	print("CHEFE musica=", som._current)
	# Todos os efeitos e vinhetas carregam?
	for f in DirAccess.get_files_at("res://assets/audio/sfx"):
		if f.ends_with(".ogg.import") or f.ends_with(".ogg"):
			var n = f.replace(".import", "")
			if load("res://assets/audio/sfx/" + n) == null:
				print("FALHA sfx ", n)
	for s in ["espada", "passo", "acerto", "fogo", "dano", "pegar", "moeda", "bau", "furia", "chefe_rugido", "letra"]:
		som.sfx(s)
		await _wait(60)
	for u in ["toque", "abrir", "fechar", "confirmar", "erro"]:
		som.ui(u)
		await _wait(60)
	for b in [0, 1, 2, 3, 4, 5, 6]:
		som.banner(b)
		await _wait(100)
	som.jingle("nivel")
	await _wait(500)
	print("DUCK vol=", som._music[som._active].volume_db)
	# Ifrit anda: passos tocam?
	var p = world.player
	Input.action_press("move_right")
	await _wait(800)
	Input.action_release("move_right")
	print("PASSOS ultimo=", som._last.get("passo", -1))
	p.attack()
	await _wait(200)
	print("ESPADA ultimo=", som._last.get("espada", -1))
	print("FIM")
	quit()
