"""Constrói os mapas do modo história em data/mapas/*.json.
Uso: python3 tools/construir_mapas.py  (rodar na pasta game/)

Cada mapa é desenhado com "carimbos" (casas, caminhos, lagos) sobre uma grade de caracteres.
Legenda dos tiles (ver scripts/world/tile_layer.gd):
  . areia   , grama   : caminho   f piso de madeira   c chão de caverna   * flores
  # muro    H parede de casa   R telhado   J janela   D porta   w parede interna
  T palmeira   C cacto   r rocha   K caixote   S barraca   h poço   E estante
  m mesa   b cama   P tapete   W água   = ponte   g portão   X parede de caverna   (espaço) vazio
"""
import json, os, random

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "mapas")
SOLID = set("#HRTWrmbXCS JKwhE")
MAPS = {}


class Grid:
    def __init__(self, w, h, fill="."):
        self.w, self.h = w, h
        self.g = [[fill] * w for _ in range(h)]

    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def get(self, x, y):
        return self.g[y][x]

    def rect(self, x, y, w, h, ch):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, ch)

    def border(self, ch="#"):
        for x in range(self.w):
            self.put(x, 0, ch)
            self.put(x, self.h - 1, ch)
        for y in range(self.h):
            self.put(0, y, ch)
            self.put(self.w - 1, y, ch)

    def hline(self, x1, x2, y, ch, width=1):
        for x in range(min(x1, x2), max(x1, x2) + 1):
            for d in range(width):
                self.put(x, y + d, ch)

    def vline(self, x, y1, y2, ch, width=1):
        for y in range(min(y1, y2), max(y1, y2) + 1):
            for d in range(width):
                self.put(x + d, y, ch)

    def house(self, x, y, w, door, roof=2, windows=()):
        """Telhado com 'roof' linhas e parede com porta. Devolve a posição da porta."""
        self.rect(x, y, w, roof, "R")
        self.hline(x, x + w - 1, y + roof, "H")
        for dx in windows:
            self.put(x + dx, y + roof, "J")
        self.put(x + door, y + roof, "D")
        return [x + door, y + roof]

    def stall(self, x, y, w):
        self.hline(x, x + w - 1, y, "S")

    def pond(self, x, y, w, h, palms=True):
        self.rect(x, y, w, h, "W")
        if palms:
            for px, py in ((x - 1, y - 1), (x + w, y - 1), (x - 1, y + h), (x + w, y + h)):
                self.put(px, py, "T")

    def scatter(self, ch, count, area=None, on=".", seed=1, keep_clear=()):
        rnd = random.Random(seed)
        x0, y0, w, h = area or (1, 1, self.w - 2, self.h - 2)
        placed = 0
        tries = 0
        while placed < count and tries < count * 50:
            tries += 1
            x, y = rnd.randrange(x0, x0 + w), rnd.randrange(y0, y0 + h)
            if self.get(x, y) != on:
                continue
            if any(abs(x - cx) <= 1 and abs(y - cy) <= 1 for cx, cy in keep_clear):
                continue
            self.put(x, y, ch)
            placed += 1

    def carve(self, x, y, w, h, ch="c"):
        self.rect(x, y, w, h, ch)

    def rows(self):
        return ["".join(r) for r in self.g]


ERRORS = []


def check(ok, message):
    if not ok:
        ERRORS.append(message)


def _clear_decor(grid, x, y):
    """Remove decoração espalhada (rocha, cacto, árvore, caixote) de cima de um ponto importante."""
    if grid.get(x, y) in "rCTK":
        around = [grid.get(xx, yy) for xx in range(x - 1, x + 2) for yy in range(y - 1, y + 2)
                  if 0 <= xx < grid.w and 0 <= yy < grid.h and grid.get(xx, yy) not in SOLID]
        grid.put(x, y, max(set(around), key=around.count) if around else ".")


def register(map_id, grid, **data):
    points = list(data.get("spawns", {}).values())
    points += [n["pos"] for n in data.get("npcs", []) + data.get("baus", []) + data.get("placas", []) + data.get("coletaveis", [])]
    if "chefe" in data:
        points.append(data["chefe"]["pos"])
    for x, y in points:
        _clear_decor(grid, x, y)
    data["layout"] = grid.rows()
    # Pontos de chegada e NPCs não podem cair em tiles sólidos.
    for name, (x, y) in data.get("spawns", {}).items():
        check(grid.get(x, y) not in SOLID, f"{map_id}: spawn {name} em tile sólido {grid.get(x, y)!r} ({x},{y})")
    for npc in data.get("npcs", []):
        x, y = npc["pos"]
        if not npc.get("nada"):
            check(grid.get(x, y) not in SOLID, f"{map_id}: npc {npc['id']} em tile sólido {grid.get(x, y)!r} ({x},{y})")
    for chest in data.get("baus", []) + data.get("placas", []):
        x, y = chest["pos"]
        check(grid.get(x, y) not in SOLID, f"{map_id}: objeto em tile sólido {grid.get(x, y)!r} ({x},{y})")
    MAPS[map_id] = data


def area(x, y, w=1, h=1):
    return [x, y, w, h]


# =====================================================================
# Capítulo 1: Areia Rubra
# =====================================================================

def casa_mae():
    g = Grid(16, 10, "f")
    g.rect(0, 0, 16, 2, "w")
    g.vline(0, 0, 9, "w")
    g.vline(15, 0, 9, "w")
    g.hline(0, 15, 9, "w")
    g.put(1, 2, "E")
    g.put(2, 2, "E")
    g.put(13, 2, "b")
    g.put(13, 3, "b")
    g.rect(6, 4, 2, 2, "m")
    g.rect(3, 6, 6, 2, "P")
    g.put(12, 6, "m")
    g.put(7, 9, "D")
    register("casa_mae", g,
        nome="Casa de Samira",
        moeda="brasas",
        spawns={"inicio": [12, 3], "porta": [7, 8]},
        npcs=[{"id": "samira", "pos": [4, 4]}, {"id": "kadir_casa", "pos": [9, 5], "se": {"flag": "chefe_zahrak"}}],
        saidas=[{"area": area(7, 9), "mapa": "areia_rubra", "spawn": "casa_mae"}],
        gatilhos=[{"id": "intro", "area": area(10, 2, 5, 3), "cutscene": "intro", "se": {"sem_flag": "intro_visto"}},
                  {"id": "epilogo", "area": area(6, 7, 3, 2), "cutscene": "epilogo",
                   "se": {"flag": "chefe_zahrak", "sem_flag": "epilogo_visto"}}],
        baus=[{"pos": [14, 7], "itens": {"pao": 2}, "moedas": {"brasas": 5}}],
        renascer=["casa_mae", "inicio"])


def areia_rubra():
    g = Grid(44, 32)
    g.border("#")
    # Portão norte e saída leste.
    g.put(21, 0, "g")
    g.put(22, 0, "g")
    g.vline(43, 15, 16, ":")
    # Caminhos.
    g.vline(21, 1, 12, ":", 2)
    g.rect(15, 12, 14, 7, ":")
    g.hline(29, 43, 15, ":", 2)
    g.hline(6, 21, 20, ":")
    g.vline(6, 20, 24, ":")
    g.vline(20, 18, 20, ":", 2)
    # Grama e flores perto da casa do Ancião.
    g.rect(14, 2, 6, 3, ",")
    g.rect(24, 2, 6, 3, ",")
    g.scatter("*", 6, (14, 2, 16, 3), on=",", seed=4)
    # Casas.
    g.house(17, 3, 10, door=5, roof=3, windows=(2, 7))     # Ancião Harun
    g.house(3, 21, 7, door=3, windows=(1, 5))              # Samira (casa da mãe)
    g.house(3, 4, 6, door=2, windows=(4,))                 # Vó Noor
    g.house(33, 4, 7, door=3, windows=(1, 5))              # Hassan
    g.house(33, 22, 7, door=3, windows=(1, 5))             # Layla
    g.house(12, 24, 6, door=2, windows=(4,))
    g.vline(5, 7, 9, ":")
    g.vline(36, 7, 8, ":")
    # Mercado.
    g.stall(31, 11, 3)   # Zaida
    g.stall(36, 11, 3)   # Tariq
    g.stall(30, 19, 3)   # Faruk (câmbio)
    g.put(39, 10, "K")
    g.put(40, 10, "K")
    g.put(29, 19, "K")
    g.put(14, 20, "h")
    # Natureza.
    g.scatter("T", 14, seed=7, keep_clear=[(21, 1), (6, 24), (42, 15), (5, 7), (36, 7)])
    g.scatter("C", 5, (1, 26, 42, 5), seed=9)
    g.scatter("r", 4, seed=11, keep_clear=[(21, 1), (6, 24), (42, 15)])
    register("areia_rubra", g,
        nome="Areia Rubra",
        moeda="brasas",
        spawns={"casa_mae": [6, 24], "dunas": [41, 15], "estrada": [21, 1]},
        npcs=[
            {"id": "harun", "pos": [22, 8], "se": {"sem_flag": "oitavo_fogo"}},
            {"id": "chama_areia", "pos": [21, 15]},
            {"id": "tariq", "pos": [37, 10]},
            {"id": "zaida", "pos": [32, 10]},
            {"id": "faruk", "pos": [31, 18]},
            {"id": "kiko", "pos": [10, 17], "vagar": True},
            {"id": "mimi_casa", "pos": [11, 18], "se": {"quest": "s1_gato", "estado": ["pronta", "concluida"]}},
            {"id": "noor", "pos": [6, 8]},
            {"id": "selim", "pos": [23, 1]},
            {"id": "amir", "pos": [17, 14], "vagar": True},
            {"id": "hassan", "pos": [37, 8]},
            {"id": "layla", "pos": [35, 26]},
        ],
        placas=[
            {"pos": [26, 13], "texto": "Areia Rubra: Praça da Chama Sagrada."},
            {"pos": [40, 14], "texto": "Leste: Dunas Rubras. Cuidado com os escorpiões!"},
            {"pos": [19, 2], "texto": "Norte: Estrada das Caravanas. Oásis de Miraj a três dias de caminhada."},
        ],
        baus=[{"pos": [41, 2], "itens": {"pocao_pequena": 2}, "moedas": {"brasas": 15}}],
        saidas=[
            {"area": area(6, 23), "mapa": "casa_mae", "spawn": "porta"},
            {"area": area(43, 15, 1, 2), "mapa": "dunas_rubras", "spawn": "oeste"},
            {"area": area(21, 0, 2, 1), "mapa": "estrada_caravanas", "spawn": "sul",
             "se": {"flag": "portao_norte_aberto"},
             "bloqueado": {"s": "Guarda Selim", "t": "Alto lá, Ifrit! O portão norte está fechado por ordem do Ancião."}},
        ],
        renascer=["areia_rubra", "casa_mae"])


def dunas_rubras():
    g = Grid(60, 40)
    g.border("r")
    g.vline(0, 19, 21, ":")
    # Trilha até a caverna.
    g.hline(0, 30, 20, ":")
    g.vline(30, 9, 20, ":")
    g.hline(30, 50, 9, ":")
    # Entrada da caverna.
    g.rect(43, 1, 14, 7, "X")
    g.rect(49, 5, 2, 3, "c")
    g.vline(49, 8, 9, ":", 2)
    # Oásis.
    g.pond(19, 28, 6, 3)
    g.rect(16, 26, 12, 1, ",")
    g.rect(16, 32, 12, 1, ",")
    g.scatter("C", 22, seed=21, keep_clear=[(1, 20), (49, 9), (15, 33)])
    g.scatter("r", 26, seed=22, keep_clear=[(1, 20), (49, 9), (15, 33)])
    g.scatter("T", 6, (40, 25, 18, 13), seed=23)
    herbs = [[12, 8], [25, 5], [38, 14], [8, 30], [33, 33], [52, 22], [45, 35]]
    for x, y in herbs:
        g.put(x, y, ".")
    register("dunas_rubras", g,
        nome="Dunas Rubras",
        moeda="brasas",
        spawns={"oeste": [1, 20], "caverna": [49, 9]},
        npcs=[{"id": "mimi", "pos": [15, 33], "se": {"quest": "s1_gato", "estado": "ativa"}}],
        inimigos=[
            {"tipo": "escorpiao", "qtd": 6, "area": area(6, 3, 26, 30)},
            {"tipo": "cobra", "qtd": 4, "area": area(34, 12, 22, 24)},
            {"tipo": "calango", "qtd": 4, "area": area(10, 24, 40, 14)},
        ],
        coletaveis=[{"item": "erva_do_deserto", "pos": p, "se": {"quest": "s2_ervas", "estado": ["ativa", "pronta"]}} for p in herbs],
        baus=[{"pos": [4, 37], "itens": {"pocao_pequena": 1}, "moedas": {"brasas": 20}},
              {"pos": [57, 37], "itens": {"tamara": 3}}],
        placas=[{"pos": [3, 18], "texto": "Oeste: Areia Rubra."},
                {"pos": [47, 10], "texto": "Covil do Escorpião. Não entre sem estar preparado!"}],
        saidas=[{"area": area(0, 19, 1, 3), "mapa": "areia_rubra", "spawn": "dunas"},
                {"area": area(49, 5, 2, 1), "mapa": "covil_escorpiao", "spawn": "entrada"}],
        renascer=["areia_rubra", "dunas"])


def covil_escorpiao():
    g = Grid(40, 34, "X")
    g.carve(15, 26, 10, 7)       # hall de entrada
    g.carve(19, 33, 2, 1)        # saída
    g.carve(18, 10, 4, 16)       # corredor central
    g.carve(4, 18, 11, 8)        # sala oeste
    g.carve(14, 21, 4, 2)
    g.carve(25, 19, 11, 9)       # sala leste
    g.carve(22, 22, 3, 2)
    g.carve(8, 2, 24, 8)         # arena da Rainha
    g.scatter("r", 6, (4, 18, 11, 8), on="c", seed=31)
    g.scatter("r", 6, (25, 19, 11, 9), on="c", seed=32)
    g.scatter("r", 4, (8, 2, 24, 8), on="c", seed=33, keep_clear=[(20, 5), (19, 9), (20, 9)])
    register("covil_escorpiao", g,
        nome="Covil do Escorpião",
        moeda="brasas",
        spawns={"entrada": [19, 31]},
        inimigos=[
            {"tipo": "escorpiao_negro", "qtd": 3, "area": area(18, 12, 4, 14)},
            {"tipo": "morcego", "qtd": 4, "area": area(4, 18, 11, 8)},
            {"tipo": "escorpiao_negro", "qtd": 3, "area": area(25, 19, 11, 9)},
            {"tipo": "morcego", "qtd": 2, "area": area(25, 19, 11, 9)},
        ],
        chefe={"tipo": "rainha_escorpiao", "pos": [20, 5], "flag": "chefe_rainha",
               "se": {"flag": "rainha_desperta"}, "cutscene": "rainha_derrotada"},
        gatilhos=[{"id": "arena", "area": area(18, 9, 4, 1), "cutscene": "rainha_aparece",
                   "se": {"sem_flag": "chefe_rainha"}, "uma_vez": False}],
        baus=[{"pos": [5, 19], "itens": {"pocao_media": 1}, "moedas": {"brasas": 30}},
              {"pos": [34, 26], "itens": {"pocao_pequena": 2}}],
        saidas=[{"area": area(19, 33, 2, 1), "mapa": "dunas_rubras", "spawn": "caverna"}],
        renascer=["dunas_rubras", "caverna"])


def build_all():
    for fn in (casa_mae, areia_rubra, dunas_rubras, covil_escorpiao):
        fn()
    try:
        import capitulos_2_7
        capitulos_2_7.build(Grid, register, area)
    except ImportError:
        pass
    import extras
    extras.build(Grid, register, area, MAPS)
    import casas
    casas.build(Grid, register, area, MAPS)
    # Cenário v2 (fio de Artes): contornos naturais e interiores planejados.
    import paisagem
    paisagem.build(MAPS)
    os.makedirs(OUT, exist_ok=True)
    for map_id, data in MAPS.items():
        with open(os.path.join(OUT, map_id + ".json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
    print("mapas:", ", ".join(MAPS))
    if ERRORS:
        print("\n".join(ERRORS))
        raise SystemExit(1)


if __name__ == "__main__":
    import sys
    sys.path.insert(0, os.path.dirname(__file__))
    build_all()
