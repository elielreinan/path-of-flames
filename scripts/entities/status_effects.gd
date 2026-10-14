class_name StatusEffects
extends RefCounted
## Efeitos de status (veneno, queimadura, lentidão) de um personagem.

const INFO := {
	"veneno": {"nome": "Veneno", "cor": Color(0.45, 0.9, 0.3), "duracao": 6.0, "intervalo": 1.5, "dano": 3},
	"queimadura": {"nome": "Queimadura", "cor": Color(1.0, 0.5, 0.2), "duracao": 3.0, "intervalo": 0.5, "dano": 3},
	"lentidao": {"nome": "Lentidão", "cor": Color(0.45, 0.65, 1.0), "duracao": 3.0, "lento": 0.55},
}

## nome -> {"t": tempo restante, "tick": tempo até o próximo dano}
var active := {}


func apply(effect: String, duration := -1.0) -> void:
	if not INFO.has(effect):
		return
	var info: Dictionary = INFO[effect]
	var time: float = duration if duration > 0.0 else float(info.duracao)
	if active.has(effect):
		active[effect].t = maxf(active[effect].t, time)
	else:
		active[effect] = {"t": time, "tick": float(info.get("intervalo", 0.0))}


func clear(effect := "") -> void:
	if effect == "":
		active.clear()
	else:
		active.erase(effect)


## Avança o tempo e devolve o dano a aplicar neste quadro.
func update(delta: float) -> int:
	var damage := 0
	for effect in active.keys():
		var state: Dictionary = active[effect]
		var info: Dictionary = INFO[effect]
		state.t -= delta
		if info.has("intervalo"):
			state.tick -= delta
			if state.tick <= 0.0:
				state.tick += float(info.intervalo)
				damage += int(info.dano)
		if state.t <= 0.0:
			active.erase(effect)
	return damage


func speed_multiplier() -> float:
	return float(INFO.lentidao.lento) if active.has("lentidao") else 1.0


## Cor para tingir o sprite (pisca levemente na cor do efeito mais recente).
func tint(time: float) -> Color:
	if active.is_empty():
		return Color.WHITE
	var info: Dictionary = INFO[active.keys()[-1]]
	return Color.WHITE.lerp(info.cor, 0.35 + 0.25 * sin(time * 8.0))
