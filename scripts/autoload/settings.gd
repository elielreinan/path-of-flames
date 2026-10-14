extends Node
## Configurações do jogador (controles, som, texto), salvas em user://config.cfg.

signal changed

const PATH := "user://config.cfg"
## Opções de cada configuração: o índice escolhido é o que fica salvo.
const OPTIONS := {
	"tamanho_joystick": ["Pequeno", "Médio", "Grande"],
	"tamanho_botoes": ["Pequenos", "Médios", "Grandes"],
	"opacidade": ["Baixa", "Média", "Alta"],
	"joystick_modo": ["Fixo", "Livre"],
	"velocidade_texto": ["Lenta", "Normal", "Rápida", "Instantânea"],
	"mini_mapa": ["Desligado", "Ligado"],
	"tremer_tela": ["Desligado", "Ligado"],
}
const DEFAULTS := {
	"tamanho_joystick": 1, "tamanho_botoes": 1, "opacidade": 1, "joystick_modo": 1,
	"velocidade_texto": 1, "mini_mapa": 1, "tremer_tela": 1, "volume_musica": 7, "volume_efeitos": 8,
}

var values := DEFAULTS.duplicate()


func _ready() -> void:
	for bus in ["Musica", "Efeitos"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for key in DEFAULTS:
			values[key] = int(file.get_value("jogo", key, DEFAULTS[key]))
	_apply_audio()


func get_value(key: String) -> int:
	return int(values.get(key, DEFAULTS.get(key, 0)))


func set_value(key: String, value: int) -> void:
	values[key] = value
	_apply_audio()
	var file := ConfigFile.new()
	for k in values:
		file.set_value("jogo", k, values[k])
	file.save(PATH)
	changed.emit()


func joystick_radius() -> float:
	return [34.0, 44.0, 54.0][get_value("tamanho_joystick")]


func button_scale() -> float:
	return [0.85, 1.0, 1.2][get_value("tamanho_botoes")]


func controls_alpha() -> float:
	return [0.25, 0.45, 0.7][get_value("opacidade")]


## Letras por segundo no diálogo (0 = mostra tudo de uma vez).
func text_speed() -> float:
	return [28.0, 45.0, 80.0, 0.0][get_value("velocidade_texto")]


func _apply_audio() -> void:
	for pair in [["Musica", "volume_musica"], ["Efeitos", "volume_efeitos"]]:
		var index := AudioServer.get_bus_index(pair[0])
		if index == -1:
			continue
		var level := get_value(pair[1]) / 10.0
		AudioServer.set_bus_mute(index, level <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.001)))
