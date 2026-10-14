"""Mapas dos capítulos 2 a 7. Chamado por construir_mapas.py."""


def build(Grid, register, area):
    estrada_caravanas(Grid, register, area)
    oasis_miraj(Grid, register, area)
    palacio_miraj(Grid, register, area)
    nascente_miraj(Grid, register, area)
    desfiladeiro_sal(Grid, register, area)
    porto_coral(Grid, register, area)
    navio_pirata(Grid, register, area)
    trilha_penhascos(Grid, register, area)
    vale_ventos(Grid, register, area)
    fabrica_grifo(Grid, register, area)
    mar_de_areia(Grid, register, area)
    ruinas_qadim(Grid, register, area)
    biblioteca_qadim(Grid, register, area)
    estrada_norte(Grid, register, area)
    cidadela_sal(Grid, register, area)
    quartel_varek(Grid, register, area)
    ponte_cinzas(Grid, register, area)
    trono_cinzento(Grid, register, area)


# ---------------------------------------------------------------------
# Capítulo 2: Oásis de Miraj
# ---------------------------------------------------------------------

def estrada_caravanas(Grid, register, area):
    g = Grid(34, 90)
    g.border("r")
    # Estrada em zigue-zague de sul a norte.
    g.vline(16, 70, 89, ":", 2)
    g.hline(8, 17, 70, ":", 2)
    g.vline(8, 45, 71, ":", 2)
    g.hline(8, 25, 45, ":", 2)
    g.vline(24, 20, 46, ":", 2)
    g.hline(12, 25, 20, ":", 2)
    g.vline(12, 0, 21, ":", 2)
    g.pond(22, 60, 5, 3)
    g.scatter("C", 30, seed=41, keep_clear=[(16, 88), (12, 1), (20, 52), (26, 30)])
    g.scatter("r", 30, seed=42, keep_clear=[(16, 88), (12, 1), (20, 52), (26, 30)])
    g.scatter("T", 6, (18, 55, 14, 12), seed=43)
    register("estrada_caravanas", g,
        nome="Estrada das Caravanas",
        moeda="brasas",
        spawns={"sul": [16, 88], "norte": [12, 1]},
        npcs=[{"id": "jabir", "pos": [20, 52], "se": {"quest": "s2_caravana", "estado": "ativa"}},
              {"id": "viajante_estrada", "pos": [26, 30]}],
        inimigos=[{"tipo": "hiena", "qtd": 5, "area": area(2, 55, 30, 32)},
                  {"tipo": "bandido", "qtd": 5, "area": area(2, 22, 30, 30)},
                  {"tipo": "hiena", "qtd": 4, "area": area(2, 2, 30, 18)}],
        baus=[{"pos": [3, 75], "itens": {"pocao_pequena": 2}, "moedas": {"brasas": 25}},
              {"pos": [30, 10], "itens": {"pocao_media": 1}, "moedas": {"brasas": 40}}],
        placas=[{"pos": [18, 86], "texto": "Estrada das Caravanas. Sul: Areia Rubra. Norte: Oásis de Miraj."},
                {"pos": [14, 3], "texto": "Oásis de Miraj logo à frente!"}],
        saidas=[{"area": area(16, 89, 2, 1), "mapa": "areia_rubra", "spawn": "estrada"},
                {"area": area(12, 0, 2, 1), "mapa": "oasis_miraj", "spawn": "sul"}],
        renascer=["oasis_miraj", "sul"])


def oasis_miraj(Grid, register, area):
    g = Grid(50, 44, ",")
    g.border("T")
    g.rect(1, 30, 48, 13, ".")
    # Lago central sem ponte (pedido do Eliel): um caminho dá a volta nele.
    g.rect(16, 16, 18, 10, "W")
    g.hline(14, 35, 14, ":", 2)
    g.hline(14, 35, 26, ":", 2)
    g.vline(14, 14, 27, ":", 2)
    g.vline(34, 14, 27, ":", 2)
    # Caminhos que chegam ao anel do lago.
    g.vline(24, 28, 43, ":", 2)
    g.hline(1, 13, 20, ":", 2)
    g.hline(36, 48, 20, ":", 2)
    g.vline(24, 9, 13, ":", 2)
    g.put(0, 20, ":"); g.put(0, 21, ":")
    g.put(49, 20, ":"); g.put(49, 21, ":")
    g.put(24, 43, ":"); g.put(25, 43, ":")
    # Palácio da rainha.
    g.house(16, 2, 18, door=9, roof=5, windows=(3, 6, 12, 15))
    g.rect(14, 8, 22, 1, ":")
    g.scatter("*", 12, (2, 2, 46, 12), on=",", seed=51)
    # Casas e bazar.
    g.house(3, 3, 7, door=3, windows=(1, 5))
    g.house(40, 3, 7, door=3, windows=(1, 5))
    g.house(3, 25, 7, door=3, windows=(1, 5))       # Estalagem
    g.house(40, 25, 7, door=3, windows=(1, 5))
    g.stall(28, 33, 3)
    g.stall(33, 33, 3)
    g.stall(38, 33, 3)
    g.stall(14, 33, 3)
    g.put(9, 36, "h")
    g.scatter("T", 12, (1, 30, 48, 12), seed=52, keep_clear=[(24, 42), (6, 29), (29, 32), (34, 32), (39, 32), (15, 32)])
    register("oasis_miraj", g,
        nome="Oásis de Miraj",
        moeda="brasas",
        spawns={"sul": [24, 41], "oeste": [2, 20], "leste": [47, 21], "palacio": [25, 9]},
        npcs=[
            {"id": "nadia", "pos": [27, 12], "se": {"sem_flag": "nadia_aliada"}},
            {"id": "chama_miraj", "pos": [22, 12]},
            {"id": "ferreiro_miraj", "pos": [29, 32]},
            {"id": "mercador_miraj", "pos": [34, 32]},
            {"id": "cambista_miraj", "pos": [39, 32]},
            {"id": "estalagem_miraj", "pos": [6, 29]},
            {"id": "rashid", "pos": [15, 32]},
            {"id": "kamal", "pos": [36, 23], "vagar": True},
            {"id": "cameleiro", "pos": [10, 37]},
            {"id": "crianca_miraj", "pos": [20, 38], "vagar": True},
        ],
        placas=[{"pos": [22, 41], "texto": "Oásis de Miraj, a joia do deserto."},
                {"pos": [3, 18], "texto": "Oeste: Nascente de Miraj."},
                {"pos": [46, 18], "texto": "Leste: Desfiladeiro do Sal e Porto Coral."}],
        saidas=[{"area": area(24, 43, 2, 1), "mapa": "estrada_caravanas", "spawn": "norte"},
                {"area": area(25, 7), "mapa": "palacio_miraj", "spawn": "porta"},
                {"area": area(0, 20, 1, 2), "mapa": "nascente_miraj", "spawn": "entrada",
                 "se": {"quest": "q2_antidoto", "estado": ["ativa", "pronta", "concluida"]},
                 "bloqueado": {"s": "Guarda", "t": "A nascente está interditada. Ordens da rainha."}},
                {"area": area(49, 20, 1, 2), "mapa": "desfiladeiro_sal", "spawn": "oeste",
                 "se": {"flag": "portao_miraj"},
                 "bloqueado": {"s": "Guarda", "t": "Ninguém sai da cidade enquanto a rainha estiver doente."}}],
        renascer=["oasis_miraj", "sul"])


def palacio_miraj(Grid, register, area):
    g = Grid(20, 12, "f")
    g.rect(0, 0, 20, 2, "w")
    g.vline(0, 0, 11, "w")
    g.vline(19, 0, 11, "w")
    g.hline(0, 19, 11, "w")
    g.rect(7, 2, 6, 8, "P")
    g.put(16, 2, "b")
    g.put(16, 3, "b")
    g.put(2, 2, "E"); g.put(3, 2, "E")
    g.put(9, 11, "D")
    register("palacio_miraj", g,
        nome="Palácio de Miraj",
        moeda="brasas",
        spawns={"porta": [9, 10]},
        npcs=[{"id": "yasmin", "pos": [15, 3]}, {"id": "curandeira", "pos": [4, 5]}],
        saidas=[{"area": area(9, 11), "mapa": "oasis_miraj", "spawn": "palacio"}],
        renascer=["oasis_miraj", "sul"])


def nascente_miraj(Grid, register, area):
    g = Grid(40, 36, "X")
    g.carve(16, 28, 10, 7)
    g.carve(39, 30, 1, 2)
    g.carve(26, 30, 13, 2)
    g.carve(18, 14, 5, 14)
    g.carve(4, 16, 14, 10)
    g.carve(23, 16, 13, 10)
    g.carve(6, 2, 28, 11)
    g.carve(18, 12, 5, 3)
    g.pond(8, 19, 5, 3, palms=False)
    g.pond(27, 19, 5, 3, palms=False)
    g.pond(10, 4, 4, 3, palms=False)
    g.pond(27, 4, 4, 3, palms=False)
    lotus = [[6, 17], [15, 24], [33, 17], [25, 24], [20, 20]]
    register("nascente_miraj", g,
        nome="Nascente de Miraj",
        moeda="brasas",
        spawns={"entrada": [38, 30]},
        inimigos=[{"tipo": "sapo", "qtd": 4, "area": area(4, 16, 14, 10)},
                  {"tipo": "serpentinha", "qtd": 4, "area": area(23, 16, 13, 10)},
                  {"tipo": "sapo", "qtd": 3, "area": area(16, 26, 10, 8)}],
        chefe={"tipo": "serpente_oasis", "pos": [20, 6], "flag": "chefe_serpente",
               "se": {"flag": "serpente_desperta"}, "cutscene": "serpente_derrotada"},
        gatilhos=[{"id": "arena", "area": area(18, 12, 5, 1), "cutscene": "serpente_aparece",
                   "se": {"sem_flag": "chefe_serpente", "quest": "q2_serpente", "estado": "ativa"}, "uma_vez": False}],
        coletaveis=[{"item": "flor_lotus", "pos": p} for p in lotus],
        baus=[{"pos": [5, 24], "itens": {"pocao_media": 2}, "moedas": {"brasas": 60}},
              {"pos": [34, 24], "itens": {"cimitarra": 1}}],
        saidas=[{"area": area(39, 30, 1, 2), "mapa": "oasis_miraj", "spawn": "oeste"}],
        renascer=["oasis_miraj", "oeste"])


# ---------------------------------------------------------------------
# Capítulo 3: Porto Coral
# ---------------------------------------------------------------------

def desfiladeiro_sal(Grid, register, area):
    g = Grid(100, 24)
    g.rect(0, 0, 100, 3, "#")
    g.rect(0, 21, 100, 3, "#")
    g.hline(0, 99, 11, ":", 2)
    for x in range(6, 96, 9):
        g.rect(x, 3, 3, 2 + (x % 4), "#")
        g.rect(x + 4, 18 - (x % 3), 3, 3 + (x % 3), "#")
    g.scatter("r", 40, (1, 3, 98, 18), seed=61, keep_clear=[(1, 11), (98, 11), (50, 6)])
    g.scatter("C", 12, (1, 3, 50, 18), seed=62, keep_clear=[(1, 11)])
    register("desfiladeiro_sal", g,
        nome="Desfiladeiro do Sal",
        moeda="perolas",
        spawns={"oeste": [1, 11], "leste": [98, 11]},
        npcs=[{"id": "eremita_sal", "pos": [50, 7]}],
        inimigos=[{"tipo": "hiena", "qtd": 4, "area": area(4, 4, 30, 16)},
                  {"tipo": "escorpiao_negro", "qtd": 4, "area": area(30, 4, 30, 16)},
                  {"tipo": "caranguejo", "qtd": 5, "area": area(62, 4, 34, 16)}],
        baus=[{"pos": [44, 19], "itens": {"mapa_tesouro": 1}},
              {"pos": [82, 8], "itens": {"pocao_media": 2}, "moedas": {"perolas": 15}}],
        placas=[{"pos": [3, 9], "texto": "Desfiladeiro do Sal. A partir daqui, a moeda é a Pérola."},
                {"pos": [96, 9], "texto": "Porto Coral logo adiante."}],
        saidas=[{"area": area(0, 11, 1, 2), "mapa": "oasis_miraj", "spawn": "leste"},
                {"area": area(99, 11, 1, 2), "mapa": "porto_coral", "spawn": "oeste"}],
        renascer=["oasis_miraj", "leste"])


def porto_coral(Grid, register, area):
    g = Grid(50, 40)
    g.border("#")
    g.rect(1, 28, 48, 11, "W")
    g.hline(0, 49, 39, "W")
    g.vline(0, 28, 39, "W")
    g.vline(49, 28, 39, "W")
    # Cais.
    g.vline(10, 28, 34, "=", 2)
    g.vline(30, 28, 37, "=", 2)
    g.hline(30, 40, 36, "=", 2)
    # Ruas.
    g.hline(0, 49, 14, ":", 2)
    g.vline(24, 1, 27, ":", 2)
    g.hline(8, 42, 26, ":", 2)
    g.put(0, 14, ":"); g.put(0, 15, ":")
    g.put(24, 0, ":"); g.put(25, 0, ":")
    # Casas.
    g.house(3, 3, 8, door=4, windows=(1, 6))         # Capitania
    g.house(14, 3, 7, door=3, windows=(1, 5))
    g.house(29, 3, 9, door=4, windows=(1, 7))        # Taverna
    g.house(40, 3, 7, door=3, windows=(1, 5))
    g.house(3, 18, 7, door=3, windows=(1, 5))
    g.house(36, 18, 8, door=4, windows=(1, 6))       # Estalagem
    g.stall(13, 22, 3)
    g.stall(18, 22, 3)
    g.stall(28, 22, 3)
    g.scatter("K", 10, (2, 24, 46, 3), seed=71, keep_clear=[(11, 27), (31, 27), (14, 21), (19, 21), (29, 21)])
    g.scatter("T", 6, (1, 8, 48, 5), seed=72)
    # Farol nas pedras.
    g.rect(44, 26, 4, 2, "r")
    g.put(46, 25, ".")
    register("porto_coral", g,
        nome="Porto Coral",
        moeda="perolas",
        spawns={"oeste": [1, 14], "norte": [24, 1], "cais": [37, 36]},
        npcs=[
            {"id": "murad", "pos": [7, 7]},
            {"id": "bako", "pos": [33, 7], "se": {"sem_flag": "bako_aliado"}},
            {"id": "chama_coral", "pos": [20, 15]},
            {"id": "ferreiro_coral", "pos": [14, 21]},
            {"id": "mercador_coral", "pos": [19, 21]},
            {"id": "cambista_coral", "pos": [29, 21]},
            {"id": "estalagem_coral", "pos": [40, 22]},
            {"id": "velho_zeca", "pos": [11, 27]},
            {"id": "taverneiro", "pos": [36, 8]},
            {"id": "faroleiro", "pos": [46, 24]},
            {"id": "marina", "pos": [42, 27], "se": {"quest": "s3_farol", "estado": "ativa"}},
            {"id": "marujo", "pos": [20, 12], "vagar": True},
        ],
        placas=[{"pos": [2, 12], "texto": "Porto Coral. Aqui só se aceitam Pérolas!"},
                {"pos": [26, 1], "texto": "Norte: Trilha dos Penhascos e Vale dos Ventos."}],
        saidas=[{"area": area(0, 14, 1, 2), "mapa": "desfiladeiro_sal", "spawn": "leste"},
                {"area": area(40, 36, 1, 2), "mapa": "navio_pirata", "spawn": "entrada",
                 "se": {"flag": "bako_aliado"},
                 "bloqueado": {"s": "Ifrit", "t": "O navio pirata está ancorado ali... Preciso de ajuda para invadir."}},
                {"area": area(24, 0, 2, 1), "mapa": "trilha_penhascos", "spawn": "sul",
                 "se": {"flag": "portao_coral"},
                 "bloqueado": {"s": "Guarda", "t": "A trilha está fechada até os piratas irem embora."}}],
        renascer=["porto_coral", "oeste"])


def navio_pirata(Grid, register, area):
    g = Grid(40, 26, "W")
    # Casco do navio.
    g.rect(6, 4, 28, 18, "f")
    g.hline(6, 33, 4, "w")
    g.hline(6, 33, 21, "w")
    g.vline(6, 4, 21, "w")
    g.vline(33, 4, 21, "w")
    g.put(6, 12, "="); g.put(6, 13, "=")
    g.hline(0, 6, 12, "=", 2)
    # Cabine do capitão.
    g.rect(24, 5, 9, 1, "w")
    g.hline(24, 32, 10, "w")
    g.vline(24, 5, 10, "w")
    g.put(28, 10, "f")
    g.put(29, 10, "f")
    g.scatter("K", 12, (7, 5, 16, 16), on="f", seed=81, keep_clear=[(8, 12), (8, 13)])
    g.put(16, 8, "m")
    g.put(16, 16, "m")
    register("navio_pirata", g,
        nome="Navio Pirata",
        moeda="perolas",
        spawns={"entrada": [1, 12]},
        inimigos=[{"tipo": "pirata", "qtd": 6, "area": area(10, 5, 13, 16)},
                  {"tipo": "caranguejo", "qtd": 2, "area": area(7, 14, 10, 6)}],
        chefe={"tipo": "kraal", "pos": [28, 7], "flag": "chefe_kraal",
               "se": {"flag": "kraal_desperto"}, "cutscene": "kraal_derrotado"},
        gatilhos=[{"id": "cabine", "area": area(26, 11, 6, 2), "cutscene": "kraal_aparece",
                   "se": {"sem_flag": "chefe_kraal"}, "uma_vez": False}],
        baus=[{"pos": [31, 6], "itens": {"lamina_coral": 1}, "moedas": {"perolas": 60}},
              {"pos": [8, 19], "itens": {"pocao_grande": 1}}],
        saidas=[{"area": area(0, 12, 1, 2), "mapa": "porto_coral", "spawn": "cais"}],
        renascer=["porto_coral", "cais"])


# ---------------------------------------------------------------------
# Capítulo 4: Vale dos Ventos
# ---------------------------------------------------------------------

def trilha_penhascos(Grid, register, area):
    g = Grid(32, 90, ",")
    g.border("#")
    g.vline(15, 0, 89, ":", 2)
    for y in range(6, 86, 8):
        side = (y // 8) % 2
        if side:
            g.rect(1, y, 11, 2, "#")
        else:
            g.rect(20, y, 11, 2, "#")
    g.scatter("r", 40, seed=91, keep_clear=[(15, 88), (15, 1)])
    g.scatter("*", 30, on=",", seed=92)
    sinos = [[4, 70], [27, 45], [5, 20]]
    for x, y in sinos:
        g.put(x, y, ",")
    register("trilha_penhascos", g,
        nome="Trilha dos Penhascos",
        moeda="perolas",
        spawns={"sul": [15, 88], "norte": [15, 1]},
        inimigos=[{"tipo": "lobo_metal", "qtd": 4, "area": area(1, 50, 30, 38)},
                  {"tipo": "aguia", "qtd": 4, "area": area(1, 20, 30, 30)},
                  {"tipo": "lobo_metal", "qtd": 3, "area": area(1, 2, 30, 18)}],
        coletaveis=[{"item": "sino_vento", "pos": p, "se": {"quest": "s4_sinos", "estado": ["ativa", "pronta"]}} for p in sinos],
        baus=[{"pos": [28, 80], "itens": {"pocao_grande": 1}, "moedas": {"perolas": 30}}],
        placas=[{"pos": [17, 86], "texto": "Trilha dos Penhascos. O vento aqui não para nunca."}],
        saidas=[{"area": area(15, 89, 2, 1), "mapa": "porto_coral", "spawn": "norte"},
                {"area": area(15, 0, 2, 1), "mapa": "vale_ventos", "spawn": "sul"}],
        renascer=["vale_ventos", "sul"])


def vale_ventos(Grid, register, area):
    g = Grid(48, 40, ",")
    g.border("#")
    g.vline(23, 1, 38, ":", 2)
    g.hline(1, 46, 20, ":", 2)
    g.put(23, 39, ":"); g.put(24, 39, ":")
    g.put(23, 0, ":"); g.put(24, 0, ":")
    g.put(47, 20, ":"); g.put(47, 21, ":")
    g.house(4, 4, 8, door=4, windows=(1, 6))          # Anciã Sora
    g.house(14, 4, 6, door=3, windows=(1,))           # Inventor
    g.house(30, 4, 7, door=3, windows=(1, 5))
    g.house(4, 26, 7, door=3, windows=(1, 5))         # Estalagem
    g.house(36, 26, 7, door=3, windows=(1, 5))
    g.stall(27, 15, 3)
    g.stall(32, 15, 3)
    g.stall(37, 15, 3)
    # Pasto com cerca de pedras.
    g.rect(8, 12, 12, 6, ",")
    g.hline(7, 20, 11, "r")
    g.hline(7, 20, 18, "r")
    g.vline(7, 11, 18, "r")
    g.vline(20, 11, 18, "r")
    g.put(20, 15, ",")
    g.scatter("*", 40, on=",", seed=101)
    g.scatter("T", 8, (26, 26, 20, 12), on=",", seed=102)
    register("vale_ventos", g,
        nome="Vale dos Ventos",
        moeda="perolas",
        spawns={"sul": [23, 38], "norte": [23, 1], "leste": [46, 21]},
        npcs=[
            {"id": "sora", "pos": [8, 8]},
            {"id": "tobi", "pos": [17, 8]},
            {"id": "chama_vale", "pos": [26, 22]},
            {"id": "ferreiro_vale", "pos": [28, 14]},
            {"id": "mercador_vale", "pos": [33, 14]},
            {"id": "cambista_vale", "pos": [38, 14]},
            {"id": "estalagem_vale", "pos": [7, 30]},
            {"id": "pastor", "pos": [22, 15]},
            {"id": "ovelha_1", "pos": [3, 35], "se": {"quest": "s4_ovelhas", "estado": "ativa"}},
            {"id": "ovelha_2", "pos": [44, 3], "se": {"quest": "s4_ovelhas", "estado": "ativa"}},
            {"id": "ovelha_3", "pos": [44, 36], "se": {"quest": "s4_ovelhas", "estado": "ativa"}},
            {"id": "ovelha_pasto", "pos": [12, 14], "vagar": True},
            {"id": "ovelha_pasto2", "pos": [15, 16], "vagar": True},
        ],
        placas=[{"pos": [25, 37], "texto": "Vale dos Ventos. Terra de pastores e moinhos."},
                {"pos": [45, 18], "texto": "Leste: área cercada. Perigo!"}],
        saidas=[{"area": area(23, 39, 2, 1), "mapa": "trilha_penhascos", "spawn": "norte"},
                {"area": area(47, 20, 1, 2), "mapa": "fabrica_grifo", "spawn": "entrada",
                 "se": {"quest": "q4_fabrica", "estado": ["ativa", "pronta", "concluida"]},
                 "bloqueado": {"s": "Ifrit", "t": "Uma cerca de ferro bloqueia o caminho. Melhor falar com a Anciã primeiro."}},
                {"area": area(23, 0, 2, 1), "mapa": "mar_de_areia", "spawn": "sul",
                 "se": {"flag": "portao_vale"},
                 "bloqueado": {"s": "Pastor", "t": "Ei, o Mar de Areia é perigoso! Ajude a vila primeiro."}}],
        renascer=["vale_ventos", "sul"])


def fabrica_grifo(Grid, register, area):
    g = Grid(40, 32, "#")
    g.rect(1, 22, 14, 8, ":")
    g.rect(0, 25, 1, 2, ":")
    g.rect(14, 24, 12, 3, ":")
    g.rect(25, 16, 12, 13, ":")
    g.rect(29, 12, 4, 4, ":")
    g.rect(4, 2, 32, 10, ":")
    g.scatter("K", 10, (1, 22, 14, 8), on=":", seed=111, keep_clear=[(1, 25), (1, 26)])
    g.scatter("K", 10, (25, 16, 12, 13), on=":", seed=112)
    g.scatter("K", 4, (4, 2, 32, 10), on=":", seed=113, keep_clear=[(20, 5), (30, 11)])
    register("fabrica_grifo", g,
        nome="Fábrica de Zahrak",
        moeda="perolas",
        spawns={"entrada": [1, 25]},
        inimigos=[{"tipo": "lobo_metal", "qtd": 4, "area": area(1, 22, 14, 8)},
                  {"tipo": "lobo_metal", "qtd": 4, "area": area(25, 16, 12, 13)},
                  {"tipo": "aguia", "qtd": 2, "area": area(25, 16, 12, 13)}],
        chefe={"tipo": "grifo_ferro", "pos": [20, 5], "flag": "chefe_grifo",
               "se": {"flag": "grifo_desperto"}, "cutscene": "grifo_derrotado"},
        gatilhos=[{"id": "arena", "area": area(29, 12, 4, 1), "cutscene": "grifo_aparece",
                   "se": {"sem_flag": "chefe_grifo"}, "uma_vez": False}],
        baus=[{"pos": [35, 27], "itens": {"espada_vento": 1}},
              {"pos": [2, 29], "itens": {"pocao_grande": 2}, "moedas": {"perolas": 50}}],
        saidas=[{"area": area(0, 25, 1, 2), "mapa": "vale_ventos", "spawn": "leste"}],
        renascer=["vale_ventos", "leste"])


# ---------------------------------------------------------------------
# Capítulo 5: Ruínas de Qadim
# ---------------------------------------------------------------------

def mar_de_areia(Grid, register, area):
    """O Vale dos Ventos fica ao sul da ponta oeste do Mar de Areia: quem sai pelo norte do vale
    desce a encosta e chega pela borda sul. A estrada atravessa o deserto até Qadim, a leste."""
    g = Grid(110, 30)
    g.border("r")
    g.hline(8, 109, 15, ":", 2)
    g.vline(8, 15, 29, ":", 2)
    # Encosta do vale: grama rala e pedras na descida.
    g.rect(1, 22, 20, 7, ",")
    g.scatter(".", 30, (1, 22, 20, 7), on=",", seed=120)
    g.vline(8, 22, 29, ":", 2)
    g.scatter("r", 10, (1, 20, 20, 9), on=",", seed=123, keep_clear=[(8, 28), (9, 28), (8, 24), (9, 24)])
    g.pond(50, 5, 6, 3)
    g.pond(80, 22, 5, 3)
    g.scatter("C", 45, seed=121, keep_clear=[(8, 28), (108, 15), (53, 12)])
    g.scatter("r", 45, seed=122, keep_clear=[(8, 28), (108, 15), (53, 12)])
    for x in range(8, 10):
        for y in range(15, 30):
            g.put(x, y, ":")
    register("mar_de_areia", g,
        nome="Mar de Areia",
        moeda="coroas",
        # "oeste" continua existindo para saves antigos que pararam na entrada.
        spawns={"sul": [8, 28], "oeste": [8, 28], "leste": [108, 15]},
        npcs=[{"id": "caravana_perdida", "pos": [53, 12]}],
        inimigos=[{"tipo": "escorpiao_cristal", "qtd": 5, "area": area(12, 2, 40, 18)},
                  {"tipo": "mumia", "qtd": 5, "area": area(55, 2, 52, 26)},
                  {"tipo": "aguia", "qtd": 3, "area": area(30, 2, 50, 26)}],
        baus=[{"pos": [20, 27], "itens": {"pocao_grande": 2}, "moedas": {"coroas": 20}},
              {"pos": [95, 2], "itens": {"elixir": 1}}],
        placas=[{"pos": [10, 25], "texto": "Sul: descida para o Vale dos Ventos. Norte: o Mar de Areia, terra das Coroas."},
                {"pos": [11, 13], "texto": "Leste: Ruínas de Qadim."}],
        saidas=[{"area": area(8, 29, 2, 1), "mapa": "vale_ventos", "spawn": "norte"},
                {"area": area(109, 15, 1, 2), "mapa": "ruinas_qadim", "spawn": "oeste"}],
        renascer=["vale_ventos", "norte"])


def ruinas_qadim(Grid, register, area):
    g = Grid(48, 40)
    g.border("#")
    # Muros quebrados e colunas.
    for x, y, w in ((4, 4, 8), (30, 4, 10), (4, 30, 6), (34, 32, 8), (16, 26, 5)):
        g.hline(x, x + w, y, "#")
    for x in range(8, 40, 6):
        g.put(x, 12, "r")
        g.put(x, 18, "r")
    g.hline(0, 47, 15, ":", 2)
    g.vline(23, 1, 38, ":", 2)
    g.put(0, 15, ":"); g.put(0, 16, ":")
    g.put(23, 0, ":"); g.put(24, 0, ":")
    g.put(47, 15, ":"); g.put(47, 16, ":")
    g.house(4, 20, 7, door=3, windows=(1, 5))      # Casa de Omar
    g.house(36, 20, 7, door=3, windows=(1, 5))     # Estalagem
    g.stall(27, 9, 3)
    g.stall(32, 9, 3)
    g.stall(37, 9, 3)
    g.scatter("C", 8, seed=131, keep_clear=[(1, 15), (23, 1), (46, 15)])
    register("ruinas_qadim", g,
        nome="Ruínas de Qadim",
        moeda="coroas",
        spawns={"oeste": [1, 15], "norte": [23, 1], "leste": [46, 16]},
        npcs=[
            {"id": "omar", "pos": [7, 24], "se": {"sem_flag": "omar_aliado"}},
            {"id": "chama_qadim", "pos": [20, 14]},
            {"id": "ferreiro_qadim", "pos": [28, 8]},
            {"id": "mercador_qadim", "pos": [33, 8]},
            {"id": "cambista_qadim", "pos": [38, 8]},
            {"id": "estalagem_qadim", "pos": [39, 24]},
            {"id": "estatua_1", "pos": [10, 9]},
            {"id": "estatua_2", "pos": [16, 33]},
            {"id": "estatua_3", "pos": [42, 28]},
            {"id": "arqueologa", "pos": [27, 18]},
        ],
        placas=[{"pos": [25, 3], "texto": "Norte: Grande Biblioteca de Qadim."},
                {"pos": [45, 13], "texto": "Leste: Estrada do Norte e Cidadela de Sal."}],
        saidas=[{"area": area(0, 15, 1, 2), "mapa": "mar_de_areia", "spawn": "leste"},
                {"area": area(23, 0, 2, 1), "mapa": "biblioteca_qadim", "spawn": "entrada",
                 "se": {"aliado": "omar"},
                 "bloqueado": {"s": "Ifrit", "t": "A porta da biblioteca está selada com runas. Talvez alguém aqui saiba abrir."}},
                {"area": area(47, 15, 1, 2), "mapa": "estrada_norte", "spawn": "oeste",
                 "se": {"flag": "portao_qadim"},
                 "bloqueado": {"s": "Ifrit", "t": "Ainda não terminei o que vim fazer em Qadim."}}],
        renascer=["ruinas_qadim", "oeste"])


def biblioteca_qadim(Grid, register, area):
    g = Grid(40, 36, "w")
    g.rect(14, 26, 12, 9, "f")
    g.rect(19, 35, 2, 1, "f")
    g.rect(3, 14, 34, 11, "f")
    g.rect(17, 25, 6, 1, "f")
    g.rect(6, 2, 28, 10, "P")
    g.rect(18, 12, 4, 2, "f")
    for y in (16, 19, 22):
        g.hline(5, 14, y, "E")
        g.hline(25, 34, y, "E")
    g.hline(15, 24, 28, "E")
    books = [[4, 15], [35, 23], [15, 20], [24, 17]]
    register("biblioteca_qadim", g,
        nome="Grande Biblioteca",
        moeda="coroas",
        spawns={"entrada": [19, 33]},
        npcs=[{"id": "bibliotecario", "pos": [20, 23]}],
        inimigos=[{"tipo": "mumia", "qtd": 4, "area": area(3, 14, 34, 11)},
                  {"tipo": "escorpiao_cristal", "qtd": 3, "area": area(14, 26, 12, 8)}],
        chefe={"tipo": "golem_vidro", "pos": [20, 5], "flag": "chefe_golem",
               "se": {"flag": "golem_desperto"}, "cutscene": "golem_derrotado"},
        gatilhos=[{"id": "arena", "area": area(18, 12, 4, 1), "cutscene": "golem_aparece",
                   "se": {"sem_flag": "chefe_golem"}, "uma_vez": False}],
        coletaveis=[{"item": "livro_perdido", "pos": p, "se": {"quest": "s5_livros", "estado": ["ativa", "pronta"]}} for p in books],
        baus=[{"pos": [36, 15], "itens": {"lamina_qadim": 1}},
              {"pos": [15, 33], "itens": {"elixir": 1}, "moedas": {"coroas": 40}}],
        saidas=[{"area": area(19, 35, 2, 1), "mapa": "ruinas_qadim", "spawn": "norte"}],
        renascer=["ruinas_qadim", "norte"])


# ---------------------------------------------------------------------
# Capítulo 6: Cidadela de Sal
# ---------------------------------------------------------------------

def estrada_norte(Grid, register, area):
    g = Grid(100, 26, ",")
    g.border("r")
    g.rect(50, 1, 49, 24, ".")
    g.hline(0, 99, 12, ":", 2)
    g.scatter("T", 20, (1, 1, 48, 24), on=",", seed=141, keep_clear=[(1, 12), (30, 9)])
    # A estrada vira para o norte no fim: a Cidadela fica acima, e o portão dela é ao sul.
    g.put(99, 12, "r"); g.put(99, 13, "r")
    g.hline(94, 98, 12, ".", 2)
    g.vline(94, 0, 13, ":", 2)
    g.scatter("r", 30, seed=142, keep_clear=[(1, 12), (94, 1), (95, 1), (30, 9), (70, 16)])
    register("estrada_norte", g,
        nome="Estrada do Norte",
        moeda="coroas",
        spawns={"oeste": [1, 12], "leste": [94, 1]},
        npcs=[{"id": "desertor_1", "pos": [30, 9], "se": {"quest": "s6_desertores", "estado": "ativa"}},
              {"id": "desertor_2", "pos": [70, 16], "se": {"quest": "s6_desertores", "estado": "ativa"}}],
        inimigos=[{"tipo": "soldado", "qtd": 5, "area": area(10, 2, 40, 22)},
                  {"tipo": "soldado", "qtd": 5, "area": area(55, 2, 40, 22)},
                  {"tipo": "mumia", "qtd": 2, "area": area(55, 2, 40, 22)}],
        baus=[{"pos": [48, 2], "itens": {"pocao_grande": 2}, "moedas": {"coroas": 40}}],
        saidas=[{"area": area(0, 12, 1, 2), "mapa": "ruinas_qadim", "spawn": "leste"},
                {"area": area(94, 0, 2, 1), "mapa": "cidadela_sal", "spawn": "sul"}],
        renascer=["ruinas_qadim", "leste"])


def cidadela_sal(Grid, register, area):
    g = Grid(50, 40, ":")
    g.border("#")
    g.hline(1, 48, 30, "#")
    g.put(24, 30, "g"); g.put(25, 30, "g")
    g.rect(1, 31, 48, 8, ".")
    g.vline(24, 31, 39, ":", 2)
    g.put(24, 0, "g"); g.put(25, 0, "g")
    g.put(49, 16, "g"); g.put(49, 17, "g")
    g.house(4, 3, 12, door=6, roof=3, windows=(2, 9))      # Quartel-general (Rana)
    g.house(34, 3, 12, door=6, roof=3, windows=(2, 9))
    g.house(4, 18, 8, door=4, windows=(1, 6))              # Enfermaria
    g.house(38, 18, 8, door=4, windows=(1, 6))             # Estalagem
    g.stall(18, 22, 3)
    g.stall(23, 22, 3)
    g.stall(28, 22, 3)
    g.scatter("K", 10, (2, 10, 46, 6), on=":", seed=151, keep_clear=[(10, 8), (24, 12), (8, 21), (42, 22)])
    register("cidadela_sal", g,
        nome="Cidadela de Sal",
        moeda="coroas",
        spawns={"sul": [24, 37], "norte": [24, 1], "leste": [48, 16]},
        npcs=[
            {"id": "rana", "pos": [10, 8]},
            {"id": "chama_cidadela", "pos": [24, 12]},
            {"id": "ferreiro_cidadela", "pos": [19, 21]},
            {"id": "mercador_cidadela", "pos": [24, 21]},
            {"id": "cambista_negro", "pos": [29, 21]},
            {"id": "estalagem_cidadela", "pos": [42, 22]},
            {"id": "nadia_ferida", "pos": [8, 22], "se": {"flag": "nadia_ferida"}},
            {"id": "armeiro", "pos": [40, 8]},
            {"id": "soldada_ana", "pos": [30, 14], "vagar": True},
        ],
        placas=[{"pos": [22, 33], "texto": "Cidadela de Sal. Ordem e disciplina."}],
        saidas=[{"area": area(24, 39, 2, 1), "mapa": "estrada_norte", "spawn": "leste"},
                {"area": area(24, 0, 2, 1), "mapa": "quartel_varek", "spawn": "entrada",
                 "se": {"quest": "q6_varek", "estado": ["ativa", "pronta", "concluida"]},
                 "bloqueado": {"s": "Soldado", "t": "O quartel do General é proibido para civis."}},
                {"area": area(49, 16, 1, 2), "mapa": "ponte_cinzas", "spawn": "oeste",
                 "se": {"flag": "ponte_aberta"},
                 "bloqueado": {"s": "Soldado", "t": "A Ponte das Cinzas está fechada por ordem do General Varek."}}],
        renascer=["cidadela_sal", "sul"])


def quartel_varek(Grid, register, area):
    g = Grid(40, 30, "#")
    g.rect(16, 22, 8, 7, ":")
    g.rect(19, 29, 2, 1, ":")
    g.rect(4, 14, 32, 8, ":")
    g.rect(18, 11, 4, 3, ":")
    g.rect(6, 2, 28, 9, "P")
    g.scatter("K", 8, (4, 14, 32, 8), on=":", seed=161, keep_clear=[(19, 13), (20, 13)])
    g.put(8, 3, "E"); g.put(9, 3, "E"); g.put(30, 3, "E"); g.put(31, 3, "E")
    register("quartel_varek", g,
        nome="Quartel do General",
        moeda="coroas",
        spawns={"entrada": [19, 27]},
        inimigos=[{"tipo": "soldado", "qtd": 6, "area": area(4, 14, 32, 8)},
                  {"tipo": "soldado", "qtd": 2, "area": area(16, 22, 8, 6)}],
        chefe={"tipo": "varek", "pos": [20, 5], "flag": "chefe_varek",
               "se": {"flag": "varek_desperto"}, "cutscene": "varek_derrotado"},
        gatilhos=[{"id": "arena", "area": area(18, 11, 4, 1), "cutscene": "varek_aparece",
                   "se": {"sem_flag": "chefe_varek"}, "uma_vez": False}],
        baus=[{"pos": [5, 15], "itens": {"espada_sal": 1}},
              {"pos": [34, 20], "itens": {"elixir": 1}, "moedas": {"coroas": 60}}],
        saidas=[{"area": area(19, 29, 2, 1), "mapa": "cidadela_sal", "spawn": "norte"}],
        renascer=["cidadela_sal", "norte"])


# ---------------------------------------------------------------------
# Capítulo 7: Trono Cinzento
# ---------------------------------------------------------------------

def ponte_cinzas(Grid, register, area):
    g = Grid(90, 22, " ")
    g.rect(0, 8, 6, 6, "c")
    g.rect(84, 8, 6, 6, "c")
    g.hline(6, 83, 10, "=", 2)
    for x in (24, 44, 64):
        g.rect(x, 6, 6, 10, "c")
    # Escadaria subindo da plataforma leste até o portão sul do Trono Cinzento.
    g.rect(85, 0, 2, 8, "c")
    register("ponte_cinzas", g,
        nome="Ponte das Cinzas",
        moeda="coroas",
        spawns={"oeste": [1, 10], "leste": [85, 1]},
        inimigos=[{"tipo": "sombra", "qtd": 4, "area": area(24, 6, 26, 10)},
                  {"tipo": "cavaleiro", "qtd": 2, "area": area(44, 6, 6, 10)},
                  {"tipo": "sombra", "qtd": 3, "area": area(64, 6, 6, 10)}],
        baus=[{"pos": [27, 7], "itens": {"elixir": 1}},
              {"pos": [67, 14], "itens": {"pocao_grande": 3}}],
        saidas=[{"area": area(0, 10, 1, 2), "mapa": "cidadela_sal", "spawn": "leste"},
                {"area": area(85, 0, 2, 1), "mapa": "trono_cinzento", "spawn": "entrada"}],
        renascer=["cidadela_sal", "leste"])


def trono_cinzento(Grid, register, area):
    g = Grid(44, 44, "X")
    g.carve(18, 36, 8, 7)
    g.carve(21, 43, 2, 1)
    g.carve(20, 24, 4, 12)
    g.carve(4, 26, 16, 8)     # prisão
    g.carve(24, 26, 16, 8)
    g.hline(4, 19, 29, "#")
    g.put(10, 29, "c")
    g.carve(6, 2, 32, 16)     # salão do trono
    g.rect(20, 18, 4, 6, "c")
    g.rect(19, 3, 6, 12, "P")
    register("trono_cinzento", g,
        nome="Trono Cinzento",
        moeda="coroas",
        spawns={"entrada": [21, 41]},
        npcs=[{"id": "kadir_preso", "pos": [10, 27], "se": {"sem_flag": "kadir_livre"}}],
        inimigos=[{"tipo": "cavaleiro", "qtd": 3, "area": area(20, 24, 4, 12)},
                  {"tipo": "sombra", "qtd": 4, "area": area(24, 26, 16, 8)},
                  {"tipo": "cavaleiro", "qtd": 2, "area": area(4, 30, 16, 4)}],
        chefe={"tipo": "zahrak", "pos": [21, 6], "flag": "chefe_zahrak",
               "se": {"flag": "zahrak_desperto"}, "cutscene": "zahrak_derrotado"},
        gatilhos=[{"id": "trono", "area": area(20, 19, 4, 1), "cutscene": "zahrak_aparece",
                   "se": {"sem_flag": "chefe_zahrak", "flag": "kadir_livre"}, "uma_vez": False},
                  {"id": "sem_kadir", "area": area(20, 21, 4, 1), "dialogo": "trono_sem_kadir",
                   "se": {"sem_flag": "kadir_livre"}, "uma_vez": False}],
        baus=[{"pos": [38, 32], "itens": {"elixir": 2}, "moedas": {"coroas": 100}}],
        saidas=[{"area": area(21, 43, 2, 1), "mapa": "ponte_cinzas", "spawn": "leste"}],
        renascer=["trono_cinzento", "entrada"])
