"""Interiores planejados das casas (lar_*): cômodos, cozinha, quarto, sala, decoração por cidade e por morador.
Chamado por paisagem.build(MAPS). Reescreve layout, spawns, saídas e posição dos moradores de cada lar_*,
e grava "decoracao" (lista de móveis com sprite e posição) que o assador de cenário desenha.

Colisão: móvel sólido vira 'm' no layout; tapetes e banquinhos não ocupam o tile.
"""
import hashlib
from collections import deque

W, H = 14, 11
PORTA = (7, 10)
ENTRADA = (7, 9)

# letra -> (sprite, sólido)
MOVEIS = {
    "1": ("cama", True), "2": ("cama", True), "3": ("cama", True), "4": ("cama", True),
    "e": ("estante_livros", True), "o": ("estante_livros", True),
    "g": ("gaveteiro", True), "a": ("armario", True), "c": ("comoda", True),
    "p": ("bacia", True), "m": ("mesa", True), "M": ("mesa_grande", True),
    "q": ("banquinho", False), "n": ("banco", True),
    "F": ("fogao", True), "B": ("barril", True), "L": ("barril_agua", True),
    "k": ("caixote", True), "K": ("caixotes", True),
    "V": ("vaso_girassol", True), "v": ("jarro", True), "u": ("jarro_azul", True), "t": ("vaso_flor", True),
    "R": ("tapete_grande", False), "r": ("tapete", False), "s": ("tapete_redondo", False),
    "x": ("espelho", True), "z": ("balcao", True), "Y": ("trono", True),
}
CAMAS = "1234"

# Plantas: '.' chão, 'w' parede, 'D' porta. Cada bloco de letras iguais vizinhas é um móvel.
# Cômodos: quarto (camas '1'..'4', uma por morador; as que sobram viram chão), cozinha (fogão, bacia,
# barris e mesa juntos) e sala (tapete, mesa, plantas). Corredor da porta (7,8)-(7,9) sempre livre.
# "parede": decoração na face da parede de trás (linha 1): (sprite, x).
MODELOS = {
    "familia": {
        "planta": [
            "wwwwwwwwwwwwww",
            "wwwwwwwwwwwwww",
            "w1.2.3w.FpBLkw",
            "w1.2.3w......w",
            "wg...cw..MM..w",
            "www.www.qMMq.w",
            "w............w",
            "wt..RRRR....aw",
            "wV..RRRR....kw",
            "wv..........uw",
            "wwwwwwwDwwwwww",
        ],
        "parede": [("janela", 2), ("quadro", 4), ("janela", 9), ("quadro", 11)],
    },
    "pescador": {
        "planta": [
            "wwwwwwwwwwwwww",
            "wwwwwwwwwwwwww",
            "wFpLB.w1.2.3aw",
            "w.....w1.2.3.w",
            "wq.mm.wg.....w",
            "w..q..www.wwww",
            "w............w",
            "wk...RRR.....w",
            "wkk..RRR....Bw",
            "wu..........Vw",
            "wwwwwwwDwwwwww",
        ],
        "parede": [("janela", 3), ("rede", 5), ("janela", 9), ("quadro", 11)],
    },
    "mercador": {
        "planta": [
            "wwwwwwwwwwwwww",
            "wwwwwwwwwwwwww",
            "wFpLBkw1.2.3aw",
            "w.....w1.2.3.w",
            "w.MM..wg.....w",
            "wqMMq.www.wwww",
            "w............w",
            "wzz...RRRR..cw",
            "wkk...RRRR..Vw",
            "wv..........uw",
            "wwwwwwwDwwwwww",
        ],
        "parede": [("janela", 3), ("janela", 9), ("quadro", 11)],
    },
    "estudioso": {
        "planta": [
            "wwwwwwwwwwwwww",
            "wwwwwwwwwwwwww",
            "weeeeew1.2.3aw",
            "w.....w1.2.3.w",
            "w.qm..wg.....w",
            "w.....www.wwww",
            "w.....ss....ow",
            "wFp...ss....ow",
            "wB.qMMq......w",
            "wL..MM......Vw",
            "wwwwwwwDwwwwww",
        ],
        "parede": [("janela", 9), ("quadro", 11)],
    },
    "simples": {
        "planta": [
            "wwwwwwwwwwwwww",
            "wwwwwwwwwwwwww",
            "wFpLB.w.1.2.aw",
            "w.....w.1.2..w",
            "w.mm..w.....gw",
            "wq..q.ww.wwwww",
            "w............w",
            "wt...ss.....cw",
            "wk...ss.....Vw",
            "wv..........uw",
            "wwwwwwwDwwwwww",
        ],
        "parede": [("janela", 3), ("quadro", 9)],
    },
}


def vagas(planta):
    return len({ch for row in planta for ch in row if ch in CAMAS})


# Ordem dos modelos por cidade (cada casa pega o próximo), para não repetir vizinhas.
POR_CIDADE = {
    "areia_rubra": ["familia", "mercador", "simples", "estudioso", "familia"],
    "oasis_miraj": ["mercador", "familia", "estudioso", "simples"],
    "porto_coral": ["pescador", "mercador", "familia", "pescador", "simples", "estudioso"],
    "vila_pescadores": ["pescador", "simples", "pescador", "familia"],
    "vale_ventos": ["familia", "simples", "estudioso", "mercador", "familia"],
    "ruinas_qadim": ["estudioso", "simples"],
    "cidadela_sal": ["mercador", "familia", "estudioso", "simples"],
    "aldeia_tamareiras": ["simples", "familia", "mercador"],
}


def _blocos(planta):
    """Agrupa letras iguais vizinhas (4-conexas) em móveis."""
    vis = set()
    out = []
    for y, row in enumerate(planta):
        for x, ch in enumerate(row):
            if ch in MOVEIS and (x, y) not in vis:
                cel = []
                fila = [(x, y)]
                vis.add((x, y))
                while fila:
                    cx, cy = fila.pop()
                    cel.append((cx, cy))
                    for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                        if 0 <= ny < len(planta) and 0 <= nx < len(planta[ny]) and planta[ny][nx] == ch and (nx, ny) not in vis:
                            vis.add((nx, ny))
                            fila.append((nx, ny))
                out.append((ch, cel))
    return out


# Casas com eventos (spawns, gatilhos e cutscenes em posições fixas): planta própria do mesmo tamanho.
ESPECIAIS = {
    "casa_mae": {
        # Ifrit acorda em (12,3), ao lado da cama dele (1); Samira (2) e Kadir (3). Linha 4 livre: Samira anda por ela na intro.
        "planta": [
            "wwwwwwwwwwwwwwww",
            "wwwwwwwwwwwwwwww",
            "wFpLBa.w.2...13w",
            "w......w.2...13w",
            "w..............w",
            "wqMMq..........w",
            "w.MM.rrrrrr..g.w",
            "wV...rrrrrr..k.w",
            "wt..........uc.w",
            "wwwwwwwDwwwwwwww",
        ],
        "parede": [("janela", 3), ("quadro", 5), ("janela", 10), ("espelho", 12)],
        "tema": "areia_rubra",
        "camas": 3,
    },
    "palacio_miraj": {
        # Sala do trono no centro, canto da curandeira à esquerda, quarto da rainha à direita.
        "planta": [
            "wwwwwwwwwwwwwwwwwwww",
            "wwwwwwwwwwwwwwwwwwww",
            "weeee.V..Y..V.wa1.gw",
            "w.......RRR...w.1..w",
            "w.MM....RRR...w...cw",
            "wqMM....RRR........w",
            "wp......RRR........w",
            "wV.....tRRRt......Vw",
            "wu......RRR.......uw",
            "wt.....VRRRV......tw",
            "w.......RRR........w",
            "wwwwwwwwwDwwwwwwwwww",
        ],
        "parede": [("janela", 2), ("quadro", 7), ("quadro", 11), ("janela", 16)],
        "tema": "oasis_miraj",
        "camas": 1,
    },
}


def montar(nome, modelo=None, camas=None):
    modelo = modelo or MODELOS[nome]
    planta = modelo["planta"]
    # Uma cama por morador (mínimo 1); as vagas que sobram viram chão.
    n = max(1, camas if camas is not None else modelo.get("camas", vagas(planta)))
    planta = ["".join("." if ch in CAMAS and int(ch) > n else ch for ch in row) for row in planta]
    if modelo is MODELOS.get(nome):
        assert len(planta) == H and all(len(r) == W for r in planta), nome
    assert all(len(r) == len(planta[0]) for r in planta), nome
    layout = []
    for row in planta:
        out = ""
        for ch in row:
            if ch in "wD":
                out += ch
            elif ch in MOVEIS and MOVEIS[ch][1]:
                out += "m"
            else:
                out += "f"
        layout.append(out)
    deco = []
    for ch, cel in _blocos(planta):
        xs = [c[0] for c in cel]
        ys = [c[1] for c in cel]
        deco.append({"s": MOVEIS[ch][0], "area": [min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1]})
    for s, x in modelo["parede"]:
        deco.append({"s": s, "area": [x, 1, 1, 1], "parede": True})
    return layout, deco


def _anda(layout, x, y):
    return 0 <= y < H and 0 <= x < W and layout[y][x] in "fP"


def _alcance(layout, start):
    vis = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in vis and _anda(layout, nx, ny):
                vis.add((nx, ny))
                q.append((nx, ny))
    return vis


def _lugares(layout, deco, n, seed):
    """Escolhe n lugares para moradores: chão alcançável, perto de móveis, fora do corredor da porta e espalhados."""
    alc = _alcance(layout, ENTRADA)
    corredor = {(7, 9), (7, 8), (6, 9), (8, 9)}
    perto = set()
    for d in deco:
        if d.get("parede"):
            continue
        x, y, w, h = d["area"]
        for yy in range(y - 1, y + h + 1):
            for xx in range(x - 1, x + w + 1):
                perto.add((xx, yy))
    cand = sorted(p for p in alc if p not in corredor and p in perto)
    if len(cand) < n:
        cand += sorted(p for p in alc if p not in corredor and p not in cand)
    rnd = int(hashlib.md5(str(seed).encode()).hexdigest()[:8], 16)
    escolhidos = []
    while len(escolhidos) < n and cand:
        # O mais longe dos já escolhidos (desempate pelo hash).
        def score(p):
            dmin = min((abs(p[0] - q[0]) + abs(p[1] - q[1]) for q in escolhidos), default=99)
            return (dmin, (p[0] * 31 + p[1] * 17 + rnd) % 13)
        p = max(cand, key=score)
        escolhidos.append(p)
        cand.remove(p)
    return escolhidos


def validar(layout, entrada=ENTRADA, porta=PORTA):
    hh, ww = len(layout), len(layout[0])
    alc = _alcance_em(layout, entrada)
    chao = {(x, y) for y in range(hh) for x in range(ww) if layout[y][x] in "fP"}
    assert chao == alc, f"chão isolado: {sorted(chao - alc)}"
    # Nada na frente da porta: a entrada e o tile acima dela ficam livres.
    px, py = porta
    assert layout[py - 1][px] in "fP" and layout[py - 2][px] in "fP", "porta bloqueada"


def _alcance_em(layout, start):
    hh, ww = len(layout), len(layout[0])
    vis = {tuple(start)}
    q = deque([tuple(start)])
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < ww and 0 <= ny < hh and (nx, ny) not in vis and layout[ny][nx] in "fP":
                vis.add((nx, ny))
                q.append((nx, ny))
    return vis


def especiais(MAPS, extras=()):
    for mid, modelo in ESPECIAIS.items():
        if mid not in MAPS:
            continue
        data = MAPS[mid]
        layout, deco = montar(mid, modelo)
        pts = list(data.get("spawns", {}).values()) + [e["pos"] for e in data.get("npcs", []) + data.get("baus", [])]
        for gt in data.get("gatilhos", []):
            x, y, w, h = gt["area"]
            pts.append([x + w // 2, y + h // 2])
        pts += [list(p) for p in extras if 0 <= p[1] < len(layout) and 0 <= p[0] < len(layout[0]) and data["layout"][p[1]][p[0]] in "fP"]
        alc = None
        for x, y in pts:
            assert layout[y][x] in "fP", f"{mid}: ponto {x},{y} ficou sob um móvel"
        hh, ww = len(layout), len(layout[0])
        start = tuple(data["spawns"]["porta"])
        vis = {start}
        fila = deque([start])
        while fila:
            x, y = fila.popleft()
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < ww and 0 <= ny < hh and (nx, ny) not in vis and layout[ny][nx] in "fP":
                    vis.add((nx, ny))
                    fila.append((nx, ny))
        for x, y in pts:
            assert (x, y) in vis, f"{mid}: ponto {x},{y} sem acesso"
        porta = next((x, y) for y, row in enumerate(layout) for x, ch in enumerate(row) if ch == "D")
        validar(layout, start, porta)
        data["layout"] = layout
        data["decoracao"] = deco
        data["tema"] = modelo["tema"]


def build(MAPS, extras=()):
    especiais(MAPS, extras)
    cont = {}
    for mid in sorted(MAPS):
        if not mid.startswith("lar_"):
            continue
        data = MAPS[mid]
        city = mid[len("lar_"):].rsplit("_", 1)[0]
        n = int(mid.rsplit("_", 1)[1])
        ordem = POR_CIDADE.get(city, list(MODELOS))
        nome = ordem[(n - 1) % len(ordem)]
        fixos = [e for e in data.get("npcs", []) if e["id"].startswith("lar_x_")]
        moradores = [e for e in data.get("npcs", []) if not e["id"].startswith("lar_x_")]
        if vagas(MODELOS[nome]["planta"]) < len(moradores):
            nome = next(k for k in ordem + list(MODELOS) if vagas(MODELOS[k]["planta"]) >= len(moradores))
        layout, deco = montar(nome, camas=len(moradores))
        validar(layout)
        data["layout"] = layout
        data["decoracao"] = deco
        data["tema"] = city
        data["spawns"] = {"porta": list(ENTRADA)}
        for s in data.get("saidas", []):
            s["area"] = [PORTA[0], PORTA[1], 1, 1]
        for e, p in zip(moradores, _lugares(layout, deco, len(moradores), mid)):
            e["pos"] = list(p)
        # Bilhetes e itens soltos: ao lado de uma mesa.
        usados = {tuple(e["pos"]) for e in moradores}
        for e in fixos:
            mesas = [d for d in deco if d["s"] in ("mesa", "mesa_grande")]
            alvo = None
            for d in mesas:
                x, y, w, h = d["area"]
                for p in [(x + w, y), (x - 1, y), (x, y + h), (x, y - 1)]:
                    if _anda(layout, *p) and p not in usados:
                        alvo = p
                        break
                if alvo:
                    break
            e["pos"] = list(alvo or _lugares(layout, deco, 1, mid + e["id"])[0])
        cont[nome] = cont.get(nome, 0) + 1
    return cont
