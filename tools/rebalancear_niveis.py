"""Rebalanceamento 2 (lista 4 do Eliel): o 1º chefe pede ~nível 15, nível máximo 80.

Converte os níveis antigos (1 a 23) para a escala nova e ajusta vida, dano e EXP dos
inimigos para que o mesmo nível relativo continue equilibrado com as fórmulas novas do Ifrit
(GameState.max_hp / attack_power). Chefes ficam mais fortes que antes.
Rodar UMA vez (marca "balanco": 2 em data/moedas.json? não: usa o arquivo .balanco).
"""
import json, os, re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(BASE, "data")
MARK = os.path.join(DATA, "balanco_v2.txt")


def g(old):
    """Nível antigo -> nível novo."""
    old = int(old)
    if old <= 4:
        return 1 + round((old - 1) * 14 / 3)
    return round(15 + (old - 4) * 2.6)


def w_expected(old):
    """Dano da arma que o Ifrit costuma ter nesse ponto da história."""
    for limit, w in [(4, 1), (8, 2), (11, 3), (14, 4), (17, 5), (20, 7)]:
        if old <= limit:
            return w
    return 10


def atk_old(L, w): return 1 + L // 2 + 2 * w
def atk_new(L, w): return 2 + int(L * 0.6) + 3 * w
def hp_old(L): return 8 + 2 * L
def hp_new(L): return 10 + 3 * L


def load(name):
    with open(os.path.join(DATA, name), encoding="utf-8") as fh:
        return json.load(fh)


def save(name, data):
    with open(os.path.join(DATA, name), "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=1)


def main():
    if os.path.exists(MARK):
        print("Já rebalanceado (data/balanco_v2.txt existe).")
        return
    enemies = load("inimigos.json")
    for eid, e in enemies.items():
        if e.get("treino"):
            continue
        L = int(e.get("nivel", 1))
        G = g(L)
        w = w_expected(L)
        boss = "padroes" in e
        e["hp"] = max(1, round(e["hp"] * atk_new(G, w) / atk_old(L, w) * (1.3 if boss else 1.0)))
        if e.get("dano", 0) > 0:
            e["dano"] = max(1, round(e["dano"] * hp_new(G) / hp_old(L) * (1.15 if boss else 1.0)))
        e["xp"] = max(1, round(e.get("xp", 1) * (1 + G / 12)))
        e["nivel"] = G
    save("inimigos.json", enemies)

    quests = load("missoes.json")
    for q in quests.values():
        L = int(q.get("nivel", 1))
        G = g(L)
        q["nivel"] = G
        rec = q.get("recompensa", {})
        if "xp" in rec:
            rec["xp"] = round(rec["xp"] * (1 + G / 12))
    save("missoes.json", quests)

    items = load("itens.json")
    for it in items.values():
        if "defesa" in it:
            it["defesa"] = it["defesa"] * 3
        if "cura" in it and it["cura"] < 900:
            it["cura"] = it["cura"] * 3
    save("itens.json", items)

    npcs = load("npcs.json")
    def walk(node):
        if isinstance(node, dict):
            for k, v in node.items():
                if k == "nivel" and isinstance(v, int):
                    node[k] = g(v)
                else:
                    walk(v)
        elif isinstance(node, list):
            for v in node:
                walk(v)
    walk({k: v for k, v in npcs.items() if not k.startswith("lar_")})
    save("npcs.json", npcs)

    # Ferramentas de mapa (portões, missões das vilas extras, escolha de classe).
    tools = os.path.join(BASE, "tools")
    casas = open(os.path.join(tools, "casas.py"), encoding="utf-8").read()
    casas = re.sub(r'PORTOES = \{[^}]*\}', lambda m: re.sub(r'(": )(\d+)', lambda n: n.group(1) + str(g(int(n.group(2)))), m.group(0)), casas)
    casas = casas.replace('f("lar_zaira_escolha", {"nivel": 5}', 'f("lar_zaira_escolha", {"nivel": 10}')
    open(os.path.join(tools, "casas.py"), "w", encoding="utf-8").write(casas)
    extras = open(os.path.join(tools, "extras.py"), encoding="utf-8").read()
    extras = re.sub(r'("tipo": "secundaria", "nivel": )(\d+)', lambda n: n.group(1) + str(g(int(n.group(2)))), extras)
    open(os.path.join(tools, "extras.py"), "w", encoding="utf-8").write(extras)

    with open(MARK, "w") as fh:
        fh.write("Rebalanceamento 2 aplicado (tools/rebalancear_niveis.py).\n")
    print("ok")


if __name__ == "__main__":
    main()
