"""Copia os objetos do fio de Artes (arte/objetos) para o jogo como criaturas "obj_<id>".

Uso (na pasta game/): python3 tools/integrar_objetos.py
- arte/objetos/<id>.png -> assets/criaturas/obj_<id>.png
- entradas obj_<id> em data/criaturas.json (gato e ovelha ganham 4 direções; "flutuar" vira "parado").
O npc.gd troca o sprite antigo pelo objeto (Npc.OBJECTS) e escolhe a coluna da variante.
"""
import json
import os
import shutil

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARTE = os.path.join(os.path.dirname(GAME), "arte", "objetos")
DIRS = ["baixo", "esquerda", "cima", "direita"]

objetos = json.load(open(os.path.join(ARTE, "objetos.json"), encoding="utf-8"))
criaturas_path = os.path.join(GAME, "data", "criaturas.json")
criaturas = json.load(open(criaturas_path, encoding="utf-8"))
for oid, info in objetos.items():
    novo = "obj_" + oid
    shutil.copy(os.path.join(ARTE, info["arquivo"]), os.path.join(GAME, "assets", "criaturas", novo + ".png"))
    entrada = {"arquivo": novo + ".png", "tipo": "objeto", "frame": info["frame"], "pe": info["pe"],
               "anims": dict(info["anims"])}
    if "flutuar" in entrada["anims"]:
        entrada["anims"]["parado"] = entrada["anims"].pop("flutuar")
    if "parado_baixo" in entrada["anims"]:
        entrada["dirs"] = DIRS
        entrada["pe_dir"] = {d: info["pe"] for d in DIRS}
    if "variantes" in info:
        entrada["variantes"] = info["variantes"]
    criaturas[novo] = entrada
json.dump(criaturas, open(criaturas_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("objetos:", ", ".join(sorted(objetos)))
