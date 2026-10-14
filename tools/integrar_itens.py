"""Copia os ícones de itens do fio de Artes (arte/itens) para o jogo.

Uso (na pasta game/): python3 tools/integrar_itens.py
- arte/itens/<id>.png -> assets/itens/<id>.png e "sprite" em data/itens.json
- arte/itens/grade/<id>.png -> assets/itens/grade/<id>.png e "sprite_grade" (desenho da bolsa)
- baú, saco, coração, livro, carta e moedas substituem os genéricos em assets/.
"""
import json
import os
import shutil

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTE = os.path.join(os.path.dirname(GAME), "arte", "itens")
GENERICOS = {"bau": "bau", "bau_aberto": "bau_aberto", "saco": "saco", "coracao": "coracao",
             "livro": "livro", "carta": "carta", "moeda_brasa": "brasa", "moeda_perola": "perola",
             "moeda_coroa": "coroa"}

itens_path = os.path.join(GAME, "data", "itens.json")
itens = json.load(open(itens_path, encoding="utf-8"))
manifesto = json.load(open(os.path.join(ARTE, "itens_icones.json"), encoding="utf-8"))
os.makedirs(os.path.join(GAME, "assets", "itens", "grade"), exist_ok=True)
feitos = 0
for item_id, info in manifesto.items():
    if item_id not in itens:
        continue
    shutil.copy(os.path.join(ARTE, info["arquivo"]), os.path.join(GAME, "assets", "itens", item_id + ".png"))
    itens[item_id]["sprite"] = "res://assets/itens/%s.png" % item_id
    if "grade" in info:
        shutil.copy(os.path.join(ARTE, info["grade"]), os.path.join(GAME, "assets", "itens", "grade", item_id + ".png"))
        itens[item_id]["sprite_grade"] = "res://assets/itens/grade/%s.png" % item_id
    feitos += 1
for origem, destino in GENERICOS.items():
    src = os.path.join(ARTE, origem + ".png")
    if os.path.exists(src):
        shutil.copy(src, os.path.join(GAME, "assets", destino + ".png"))
json.dump(itens, open(itens_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
faltam = sorted(set(itens) - set(manifesto))
print("ícones:", feitos, "| sem ícone:", faltam)
