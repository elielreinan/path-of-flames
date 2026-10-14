extends Node
## Música e efeitos sonoros. A música troca com fade cruzado; os efeitos tocam num grupo de
## players. Os volumes vêm dos barramentos "Musica" e "Efeitos" (Configurações).
## Créditos e licenças em assets/audio/LICENCAS.md.

const MUSIC_DIR := "res://assets/audio/musica/"
const SFX_DIR := "res://assets/audio/sfx/"
const UI_DIR := "res://assets/audio/ui/"
const POOL_SIZE := 12
const FADE := 1.2
## Volume da música em relação aos efeitos (o jogador ajusta o resto nas Configurações).
const MUSIC_DB := -2.0
## Efeitos com mais de uma versão: sorteia uma para não cansar o ouvido.
const VARIANTS := {"espada": 3, "passo": 4}

## Vilas e cidades (o resto ao ar livre é "campo"); a moeda diz a região.
const TOWNS := ["areia_rubra", "oasis_miraj", "palacio_miraj", "aldeia_tamareiras", "porto_coral",
	"vila_pescadores", "vale_ventos", "cidadela_sal", "ruinas_qadim", "campo_treino"]
const DUNGEONS := ["covil_escorpiao", "caverna_zazu", "fabrica_grifo", "navio_pirata", "biblioteca_qadim",
	"quartel_varek", "trono_cinzento", "nascente_miraj"]
const REGION := {"brasas": "deserto", "perolas": "costa", "coroas": "norte"}
## Mapas cuja região não bate com a moeda (o Mar de Areia é deserto, mesmo pagando em coroas).
const OVERRIDE := {"mar_de_areia": "campo_deserto"}

var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _current := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last := {}
var _duck_tween: Tween
var _jingle: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Musica"
		player.volume_db = -80.0
		add_child(player)
		_music.append(player)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Efeitos"
		add_child(player)
		_pool.append(player)
	_jingle = AudioStreamPlayer.new()
	_jingle.bus = "Musica"
	add_child(_jingle)
	_jingle.finished.connect(_unduck)
	GameState.leveled_up.connect(func(_level): jingle("nivel"))
	get_tree().node_added.connect(_on_node_added)


func _load(path: String) -> AudioStream:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


# ---------- música ----------

## Troca a música de fundo (nada acontece se já for a mesma).
func music(track: String, fade := FADE) -> void:
	if track == _current:
		return
	_current = track
	var old := _music[_active]
	_active = 1 - _active
	var new := _music[_active]
	var stream := _load(MUSIC_DIR + track + ".ogg") if track != "" else null
	var tween := create_tween().set_parallel(true)
	tween.tween_property(old, "volume_db", -80.0, fade)
	tween.chain().tween_callback(old.stop)
	if stream:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		new.stream = stream
		new.volume_db = -40.0
		new.play()
		create_tween().tween_property(new, "volume_db", MUSIC_DB, fade).set_trans(Tween.TRANS_SINE)


func stop_music(fade := FADE) -> void:
	music("", fade)


## Música certa para o mapa: casa, masmorra, vila ou campo (por região).
func music_for_map(map_id: String, map_data: Dictionary) -> String:
	if map_data.get("interior", false) or map_id.begins_with("lar_") or map_id.begins_with("casa_"):
		return "interior"
	if OVERRIDE.has(map_id):
		return OVERRIDE[map_id]
	if map_id in DUNGEONS:
		return "masmorra"
	var region: String = REGION.get(map_data.get("moeda", "brasas"), "deserto")
	return ("cidade_" if map_id in TOWNS else "campo_") + region


## Vinheta curta por cima da música (que abaixa enquanto ela toca).
func jingle(track: String) -> void:
	var stream := _load(MUSIC_DIR + track + ".ogg")
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = false
	_jingle.stream = stream
	_jingle.play()
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music[_active], "volume_db", MUSIC_DB - 14.0, 0.25)


func _unduck() -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music[_active], "volume_db", MUSIC_DB, 1.0)


## Som de cada tela grande (capítulo, chefe, derrota, missão).
func banner(kind: int) -> void:
	match kind:
		Banner.Kind.CHAPTER:
			jingle("capitulo")
		Banner.Kind.BOSS_INTRO:
			sfx("chefe_rugido")
		Banner.Kind.BOSS_DEFEATED:
			jingle("chefe_vencido")
		Banner.Kind.DEFEAT:
			jingle("derrota")
		Banner.Kind.QUEST_DONE, Banner.Kind.REWARD:
			jingle("missao")
		Banner.Kind.QUEST_FAILED:
			jingle("falhou")


# ---------- efeitos ----------

## Toca um efeito. pitch_var varia um pouco o tom para soar natural.
func sfx(sound: String, volume_db := 0.0, pitch_var := 0.06, min_gap := 0.04) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(sound, -1.0)) < min_gap:
		return
	_last[sound] = now
	var file := sound
	if VARIANTS.has(sound):
		file = "%s_%d" % [sound, randi_range(1, VARIANTS[sound])]
	_play(_load(SFX_DIR + file + ".ogg"), volume_db, pitch_var)


## Sons de interface (Kenney): toque, abrir, fechar, confirmar, erro.
func ui(sound: String, volume_db := -4.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get("ui", -1.0)) < 0.05:
		return
	_last["ui"] = now
	_play(_load(UI_DIR + sound + ".ogg"), volume_db, 0.0)


func _play(stream: AudioStream, volume_db: float, pitch_var: float) -> void:
	if stream == null:
		return
	# Usa um player livre; se todos estiverem tocando, o mais antigo cede a vez.
	var player: AudioStreamPlayer = null
	for i in POOL_SIZE:
		var candidate := _pool[(_next + i) % POOL_SIZE]
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	player.play()


## Todo botão do jogo faz um clique ao ser tocado.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(ui.bind("toque"))
	elif node is Control and node.has_signal("pressed") and node.get_script() != null:
		node.connect("pressed", ui.bind("toque"))
