"""Confere se todas as referências do conteúdo (diálogos, missões, NPCs, itens, mapas) existem.
Uso: python3 tools/validar_conteudo.py  (rodar na pasta game/)"""
import json, os, glob

ROOT = os.path.join(os.path.dirname(__file__), "..")
def load(p): return json.load(open(os.path.join(ROOT, p), encoding="utf-8"))
def load_dir(p):
    out = {}
    for f in glob.glob(os.path.join(ROOT, p, "*.json")):
        out.update(json.load(open(f, encoding="utf-8")))
    return out

itens, inimigos, missoes, npcs, lojas, moedas = (load(f"data/{n}.json") for n in ("itens", "inimigos", "missoes", "npcs", "lojas", "moedas"))
dialogos, cutscenes = load_dir("data/dialogos"), load_dir("data/cutscenes")
mapas = {os.path.basename(f)[:-5]: json.load(open(f, encoding="utf-8")) for f in glob.glob(os.path.join(ROOT, "data/mapas/*.json"))}
erros = []
def need(cond, msg):
    if not cond: erros.append(msg)
def res(path, where):
    need(os.path.exists(os.path.join(ROOT, path.replace("res://", ""))), f"{where}: arquivo {path} não existe")

def check_cond(cond, where):
    if cond is None: return
    for c in (cond if isinstance(cond, list) else [cond]):
        if "quest" in c: need(c["quest"] in missoes, f"{where}: missão {c['quest']} não existe")
        if "item" in c: need(c["item"] in itens, f"{where}: item {c['item']} não existe")
        if "aliado" in c: need(c["aliado"] in npcs, f"{where}: aliado {c['aliado']} não existe")

def check_actions(actions, where):
    for a in actions:
        for k, v in a.items():
            if k in ("quest_iniciar", "quest_concluir"): need(v in missoes, f"{where}: missão {v} não existe")
            if k in ("dar_item", "remover_item"): need(v in itens, f"{where}: item {v} não existe")
            if k in ("moeda", "pagar"): need(v in moedas, f"{where}: moeda {v} não existe")
            if k in ("aliado", "remover_aliado"): need(v in npcs and "aliado" in npcs[v], f"{where}: aliado {v} inválido")
            if k == "loja": need(v in lojas, f"{where}: loja {v} não existe")
            if k == "cutscene": need(v in cutscenes, f"{where}: cutscene {v} não existe")
            if k == "dialogo": need(v in dialogos, f"{where}: diálogo {v} não existe")
            if k == "ir_mapa": need(v[0] in mapas, f"{where}: mapa {v[0]} não existe")

for i, d in dialogos.items():
    check_actions(d.get("acoes", []), f"diálogo {i}")
    for e in d.get("escolhas", []):
        check_actions(e.get("acoes", []), f"diálogo {i}")
        check_cond(e.get("se"), f"diálogo {i}")
        if "ir" in e: need(e["ir"] in dialogos, f"diálogo {i}: vai para {e['ir']} inexistente")
for i, steps in cutscenes.items():
    for s in steps:
        if s["cmd"] == "dialogo": need(s["id"] in dialogos, f"cutscene {i}: diálogo {s['id']} não existe")
        if s["cmd"] == "acoes": check_actions(s["acoes"], f"cutscene {i}")
        if s["cmd"] == "mapa": need(s["mapa"] in mapas and s["spawn"] in mapas[s["mapa"]]["spawns"], f"cutscene {i}: mapa/spawn inválido")
        if s["cmd"] == "surgir": need(s["npc"] in npcs, f"cutscene {i}: npc {s['npc']} não existe")
for i, n in npcs.items():
    for f in n.get("falas", []):
        need(f["dialogo"] in dialogos, f"npc {i}: diálogo {f['dialogo']} não existe")
        check_cond(f.get("se"), f"npc {i}")
    if "sprite" in n: res(n["sprite"], f"npc {i}")
for i, q in missoes.items():
    for o in q["objetivos"]:
        t, alvo = o["tipo"], o.get("alvo")
        if t == "matar": need(alvo in inimigos, f"missão {i}: inimigo {alvo} não existe")
        if t == "falar": need(alvo in npcs, f"missão {i}: npc {alvo} não existe")
        if t == "coletar": need(alvo in itens, f"missão {i}: item {alvo} não existe")
        if t == "ir": need(alvo in mapas, f"missão {i}: mapa {alvo} não existe")
    if "entregar_a" in q: need(q["entregar_a"] in npcs, f"missão {i}: entregar_a {q['entregar_a']} não existe")
    if "proxima" in q: need(q["proxima"] in missoes, f"missão {i}: próxima {q['proxima']} não existe")
    for it in q.get("recompensa", {}).get("itens", {}): need(it in itens, f"missão {i}: recompensa {it} não existe")
for i, l in lojas.items():
    need(l["moeda"] in moedas, f"loja {i}: moeda inválida")
    for it in l["itens"]: need(it in itens, f"loja {i}: item {it} não existe")
for i, e in inimigos.items():
    if "sprite" in e: res(e["sprite"], f"inimigo {i}")
    if "invoca" in e: need(e["invoca"] in inimigos, f"inimigo {i}: invoca {e['invoca']} não existe")
    for it in e.get("drops", {}): need(it in itens, f"inimigo {i}: drop {it} não existe")
for i, it in itens.items():
    if "sprite" in it: res(it["sprite"], f"item {i}")
for m, d in mapas.items():
    need(d.get("moeda", "brasas") in moedas, f"mapa {m}: moeda inválida")
    for n in d.get("npcs", []):
        need(n["id"] in npcs, f"mapa {m}: npc {n['id']} não existe"); check_cond(n.get("se"), f"mapa {m}")
    for s in d.get("saidas", []):
        need(s["mapa"] in mapas and s["spawn"] in mapas[s["mapa"]]["spawns"], f"mapa {m}: saída para {s['mapa']}/{s['spawn']} inválida")
        check_cond(s.get("se"), f"mapa {m}")
    for g in d.get("gatilhos", []):
        if "cutscene" in g: need(g["cutscene"] in cutscenes, f"mapa {m}: cutscene {g['cutscene']} não existe")
        if "dialogo" in g: need(g["dialogo"] in dialogos, f"mapa {m}: diálogo {g['dialogo']} não existe")
    for z in d.get("inimigos", []): need(z["tipo"] in inimigos or z["tipo"] == "dinamico", f"mapa {m}: inimigo {z['tipo']} não existe")
    if "chefe" in d:
        need(d["chefe"]["tipo"] in inimigos, f"mapa {m}: chefe inválido")
        if "cutscene" in d["chefe"]: need(d["chefe"]["cutscene"] in cutscenes, f"mapa {m}: cutscene do chefe não existe")
    for c in d.get("coletaveis", []): need(c["item"] in itens, f"mapa {m}: coletável {c['item']} não existe")
    for b in d.get("baus", []):
        for it in b.get("itens", {}): need(it in itens, f"mapa {m}: baú com {it} inexistente")
    r = d.get("renascer")
    if r: need(r[0] in mapas and r[1] in mapas[r[0]]["spawns"], f"mapa {m}: renascer inválido")
# NPCs sem mapa (só aparecem por cutscene) e diálogos não usados
usados_npc = {n["id"] for d in mapas.values() for n in d.get("npcs", [])}
aliados = {i for i, n in npcs.items() if "aliado" in n}
for i in npcs:
    if i not in usados_npc and i not in aliados:
        erros.append(f"aviso: npc {i} não aparece em nenhum mapa")
print(f"{len(mapas)} mapas, {len(npcs)} NPCs, {len(dialogos)} diálogos, {len(cutscenes)} cutscenes, {len(missoes)} missões, {len(itens)} itens, {len(inimigos)} inimigos")
print("\n".join(erros) if erros else "Tudo certo!")
