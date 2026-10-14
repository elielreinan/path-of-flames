"""Áreas extras da lista 3 ("Chamado das Brasas"): caminhos que não levavam a lugar nenhum agora levam
ao Campo de Treino, ao Cânion das Feras (cultivo de nível) e a duas vilas não essenciais.
Também guarda o segredo do Ancião Zazu e organiza as cidades (calçadas até as portas, árvores em fileiras).
Chamado por construir_mapas.build_all() depois dos capítulos e antes das casas.
"""
import json, os
from collections import deque

import casas
from casas import NPCS, ap, d, esc, f, morador

DATA = os.path.join(os.path.dirname(__file__), "..", "data")
SOLID = set("#HRTWrmbXCS JKwhE")

# Missões novas (prefixo x_), mescladas em missoes.json.
MISSOES = {
    "x_hienas": {"titulo": "Hienas no pomar", "tipo": "secundaria", "nivel": 18, "capitulo": 2,
                 "descricao": "Hienas estão roubando as tâmaras da Aldeia das Tamareiras. Salma pediu ajuda.",
                 "objetivos": [{"tipo": "matar", "alvo": "hiena", "qtd": 4, "texto": "Derrote hienas no pomar"}],
                 "entregar_a": "lar_x_salma", "recompensa": {"xp": 35, "moedas": {"brasas": 50}, "itens": {"carne_seca": 3}}},
    "x_redes": {"titulo": "Redes cortadas", "tipo": "secundaria", "nivel": 31, "capitulo": 3,
                "descricao": "Caranguejos estão cortando as redes da Vila dos Pescadores. Seu Tomé quer a praia limpa.",
                "objetivos": [{"tipo": "matar", "alvo": "caranguejo", "qtd": 5, "texto": "Derrote caranguejos na praia"}],
                "entregar_a": "lar_x_tome", "recompensa": {"xp": 60, "moedas": {"perolas": 30}, "itens": {"pocao_grande": 1}}},
    "x_treino": {"titulo": "Primeiras lições", "tipo": "secundaria", "nivel": 1, "capitulo": 1,
                 "descricao": "Mestre Sadiq quer ver você quebrar três bonecos de treino.",
                 "objetivos": [{"tipo": "matar", "alvo": "boneco_treino", "qtd": 3, "texto": "Quebre bonecos de treino"}],
                 "entregar_a": "lar_x_sadiq", "recompensa": {"xp": 15, "moedas": {"brasas": 15}, "itens": {"pocao_pequena": 2}}},
    "x_arena": {"titulo": "Campeão do Campo", "tipo": "secundaria", "nivel": 10, "capitulo": 1,
                "descricao": "Vença o desafio da arena do Campo de Treino.",
                "objetivos": [{"tipo": "flag", "alvo": "arena_vencida", "qtd": 1, "texto": "Vença as três ondas da arena"}],
                "recompensa": {"xp": 30, "itens": {"pocao_media": 2}}},
}

LOJAS = {
    "mercado_tamareiras": {"nome": "Barraca do Tio Badu", "moeda": "brasas",
                           "itens": ["tamara", "carne_seca", "pao", "pocao_pequena", "pocao_media", "antidoto"]},
    "mercado_pescadores": {"nome": "Barraca da Iara", "moeda": "perolas",
                           "itens": ["peixe", "carne_seca", "pocao_media", "pocao_grande", "antidoto"]},
}

REGIOES = {
    "campo_treino": {"nome": "Campo de Treino", "rect": [1.6, 27.4, 2.6, 1.6], "ordem": 1, "tipo": "deserto"},
    "caverna_zazu": {"nome": "???", "rect": [14.2, 30.4, 1.6, 1.2], "ordem": 1, "tipo": "caverna"},
    "aldeia_tamareiras": {"nome": "Aldeia das Tamareiras", "rect": [11.4, 20.6, 2.8, 2.0], "ordem": 2, "tipo": "cidade"},
    "canion_feras": {"nome": "Cânion das Feras", "rect": [15.4, 18.0, 3.4, 1.6], "ordem": 3, "tipo": "rocha"},
    "vila_pescadores": {"nome": "Vila dos Pescadores", "rect": [30.0, 11.4, 2.8, 2.2], "ordem": 3, "tipo": "cidade"},
}

# Onde ficam os segredos (ids em data/segredos.json) e os objetos de pós-jogo.
SEGREDOS_NPCS = [
    ("canion_feras", {"id": "lar_x_velho_canion", "pos": [58, 2]}),
    ("fabrica_grifo", {"id": "lar_x_placa_bolo", "pos": [14, 22]}),
    ("ruinas_qadim", {"id": "lar_x_sabio_qadim", "pos": [44, 36]}),
    ("vale_ventos", {"id": "lar_x_cavaleiro_sol", "pos": [2, 2]}),
    ("quartel_varek", {"id": "lar_x_prisioneiro", "pos": [35, 21], "se": {"flag": "chefe_varek"}}),
    ("dunas_rubras", {"id": "lar_x_placa_calango", "pos": [38, 25]}),
    ("vila_pescadores", {"id": "lar_x_pescador_velho", "pos": [41, 19]}),
    ("trono_cinzento", {"id": "lar_x_diario_zahrak", "pos": [34, 3], "se": {"flag": "chefe_zahrak"}}),
]

# Moedas e chefe de referência das vilas (casas.py monta os interiores).
VILAS = {"aldeia_tamareiras": ("brasas", "chefe_rainha"), "vila_pescadores": ("perolas", "chefe_kraal")}


def _rows(data):
    return [list(r) for r in data["layout"]]


def _set_rows(data, rows):
    data["layout"] = ["".join(r) for r in rows]


def _carve(data, cells, ch=":"):
    rows = _rows(data)
    for x, y in cells:
        rows[y][x] = ch
    _set_rows(data, rows)


# ---------------------------------------------------------------------
# Saídas novas nos mapas que já existem
# ---------------------------------------------------------------------

def ligar_saidas(MAPS, area):
    # Areia Rubra: a trilha perto do poço agora segue para oeste até o Campo de Treino.
    ar = MAPS["areia_rubra"]
    _carve(ar, [(x, 20) for x in range(0, 6)])
    ar["saidas"].append({"area": area(0, 20), "mapa": "campo_treino", "spawn": "leste"})
    ar["spawns"]["treino"] = [1, 20]
    ar["placas"].append({"pos": [2, 19], "texto": "Oeste: Campo de Treino do Mestre Sadiq."})

    # Estrada das Caravanas: trilha para leste até a Aldeia das Tamareiras.
    ec = MAPS["estrada_caravanas"]
    _carve(ec, [(x, 66) for x in range(10, 34)])
    ec["saidas"].append({"area": area(33, 66), "mapa": "aldeia_tamareiras", "spawn": "oeste"})
    ec["spawns"]["aldeia"] = [32, 66]
    ec.setdefault("placas", []).append({"pos": [11, 65], "texto": "Leste: Aldeia das Tamareiras."})

    # Desfiladeiro do Sal: passagem para o sul, até o Cânion das Feras.
    ds = MAPS["desfiladeiro_sal"]
    _carve(ds, [(x, y) for x in (49, 50) for y in range(13, 24)])
    ds["saidas"].append({"area": area(49, 23, 2, 1), "mapa": "canion_feras", "spawn": "norte"})
    ds["spawns"]["canion"] = [49, 21]
    ds.setdefault("placas", []).append({"pos": [47, 14], "texto": "Sul: Cânion das Feras. As feras de lá crescem junto com você."})

    # Porto Coral: a rua leste agora chega à Vila dos Pescadores.
    pc = MAPS["porto_coral"]
    pc["saidas"].append({"area": area(49, 14, 1, 2), "mapa": "vila_pescadores", "spawn": "oeste"})
    pc["spawns"]["vila"] = [48, 14]
    pc["placas"] = pc.get("placas", []) + [{"pos": [46, 13], "texto": "Leste: Vila dos Pescadores."}]

    # Dunas Rubras: o segredo. Um paredão com uma boca de caverna tapada por uma pedra.
    du = MAPS["dunas_rubras"]
    rows = _rows(du)
    for y in range(27, 36):
        for x in range(47, 58):
            rows[y][x] = "."
    for y in range(28, 31):
        for x in range(49, 56):
            rows[y][x] = "X"
    rows[30][52] = "c"
    for x, y in ((48, 34), (50, 35), (54, 35)):   # as três palmeiras "curvadas"
        rows[y][x] = "T"
    _set_rows(du, rows)
    du["empurraveis"] = [{"pos": [52, 31]}]
    du["saidas"].append({"area": area(52, 30), "mapa": "caverna_zazu", "spawn": "entrada"})
    du["spawns"]["zazu"] = [52, 32]


# ---------------------------------------------------------------------
# Mapas novos
# ---------------------------------------------------------------------

def campo_treino(Grid, register, area):
    g = Grid(36, 24)
    g.border("#")
    g.vline(35, 11, 12, ":")
    g.hline(18, 35, 11, ":", 2)
    g.rect(16, 8, 6, 8, ":")                       # praça do mestre
    # Cercado dos bonecos.
    g.rect(3, 3, 13, 7, ",")
    g.hline(3, 15, 3, "K"); g.hline(3, 15, 9, "K")
    g.vline(3, 3, 9, "K"); g.vline(15, 3, 9, "K")
    g.put(15, 6, ","); g.hline(15, 16, 6, ":")
    # Arena cercada.
    g.rect(3, 13, 12, 8, ":")
    g.hline(3, 14, 12, "K"); g.hline(3, 14, 21, "K")
    g.vline(2, 12, 21, "K"); g.vline(15, 12, 21, "K")
    g.put(15, 16, ":"); g.put(15, 17, ":"); g.hline(15, 16, 16, ":", 2)
    # Árvores em fileira e um poço.
    for x in range(20, 34, 4):
        g.put(x, 4, "T"); g.put(x, 19, "T")
    g.put(25, 9, "h")
    bonecos = [(5, 5), (8, 5), (11, 5), (6, 7), (10, 7)]
    register("campo_treino", g,
        nome="Campo de Treino",
        moeda="brasas",
        sem_montaria=False,
        spawns={"leste": [34, 11]},
        npcs=[{"id": "lar_x_sadiq", "pos": [19, 10]}, {"id": "lar_x_aprendiz", "pos": [22, 14], "vagar": True}],
        placas=[{"pos": [17, 6], "texto": "GOLPE ESPECIAL: acerte inimigos para encher a Fúria. Cheia, toque em ESPECIAL e o Ifrit gira em chamas, invencível por um instante."},
                {"pos": [21, 6], "texto": "BOTE: quando um inimigo fica vermelho e treme, ele vai pular em você. Saia da frente!"},
                {"pos": [17, 17], "texto": "ONDA DE CHOQUE: o anel dos chefes tem brechas marcadas em verde. Fique numa brecha."},
                {"pos": [21, 17], "texto": "MONTARIA: compre um camelo em Miraj ou dome uma fera cansada com a isca certa (FALAR perto dela)."},
                {"pos": [33, 9], "texto": "Campo de Treino. Leste: Areia Rubra."}],
        inimigos=[{"tipo": "boneco_treino", "qtd": 1, "area": area(x, y), "renascer": 4} for x, y in bonecos],
        arena=[4, 13, 10, 7],
        saidas=[{"area": area(35, 11, 1, 2), "mapa": "areia_rubra", "spawn": "treino"}],
        renascer=["areia_rubra", "treino"])


def canion_feras(Grid, register, area):
    g = Grid(60, 36)
    g.border("r")
    g.vline(29, 0, 8, ":", 2)
    g.hline(8, 52, 9, ":", 2)
    g.vline(8, 9, 30, ":", 2)
    g.vline(51, 9, 30, ":", 2)
    g.hline(8, 52, 29, ":", 2)
    # Pilares de pedra organizados em fileiras, como colunas do cânion.
    for y in (14, 22):
        for x in range(14, 48, 8):
            g.rect(x, y, 3, 2, "X")
    g.scatter("C", 18, (12, 12, 36, 15), seed=91)
    g.scatter("r", 12, (2, 2, 56, 32), seed=92, keep_clear=[(29, 1), (30, 1)])
    register("canion_feras", g,
        nome="Cânion das Feras",
        moeda="perolas",
        spawns={"norte": [29, 1]},
        inimigos=[
            {"tipo": "dinamico", "qtd": 4, "area": area(11, 11, 16, 8), "renascer": 6},
            {"tipo": "dinamico", "qtd": 4, "area": area(33, 11, 16, 8), "renascer": 6},
            {"tipo": "dinamico", "qtd": 4, "area": area(11, 20, 16, 8), "renascer": 6},
            {"tipo": "dinamico", "qtd": 4, "area": area(33, 20, 16, 8), "renascer": 6},
            {"tipo": "dinamico", "qtd": 3, "area": area(20, 30, 20, 4), "renascer": 6},
        ],
        baus=[{"pos": [57, 33], "itens": {"pocao_grande": 1, "carne_seca": 2}, "moedas": {"perolas": 25}},
              {"pos": [2, 33], "itens": {"elixir": 1}}],
        placas=[{"pos": [31, 2], "texto": "Cânion das Feras: as feras daqui ficam do seu tamanho. Bom lugar para ganhar nível."}],
        saidas=[{"area": area(29, 0, 2, 1), "mapa": "desfiladeiro_sal", "spawn": "canion"}],
        renascer=["desfiladeiro_sal", "canion"])


def aldeia_tamareiras(Grid, register, area):
    g = Grid(40, 30, ",")
    g.border("T")
    g.vline(0, 14, 15, ":")
    g.hline(0, 38, 14, ":", 2)
    g.vline(19, 4, 26, ":", 2)
    # Canal de irrigação com ponte.
    g.rect(1, 20, 38, 1, "W")
    g.put(19, 20, "="); g.put(20, 20, "=")
    # Casas alinhadas ao norte da rua principal.
    g.house(3, 8, 7, door=3, windows=(1, 5))
    g.house(12, 8, 6, door=2, windows=(4,))
    g.house(23, 8, 7, door=3, windows=(1, 5))
    # Pomar: tamareiras em grade, bem organizadas.
    for y in range(23, 28, 2):
        for x in range(4, 37, 3):
            if x not in (19, 20, 22):
                g.put(x, y, "T")
    g.stall(31, 11, 3)
    g.put(35, 11, "K"); g.put(36, 11, "K")
    g.put(10, 17, "h")
    g.scatter("*", 10, (2, 2, 36, 5), on=",", seed=71)
    register("aldeia_tamareiras", g,
        nome="Aldeia das Tamareiras",
        moeda="brasas",
        spawns={"oeste": [1, 14]},
        npcs=[{"id": "lar_x_salma", "pos": [22, 16]}, {"id": "lar_x_badu", "pos": [32, 10]},
              {"id": "lar_x_zuleica", "pos": [9, 16]}, {"id": "lar_x_safira", "pos": [28, 16]},
              {"id": "lar_x_tico", "pos": [14, 18], "vagar": True},
              {"id": "lar_x_nadador_canal", "nada": True, "pos": [8, 20], "vagar": True}],
        inimigos=[{"tipo": "hiena", "qtd": 3, "area": area(2, 22, 36, 6), "se": {"quest": "x_hienas", "estado": "ativa"}}],
        placas=[{"pos": [2, 12], "texto": "Aldeia das Tamareiras. As tâmaras mais doces do deserto."}],
        saidas=[{"area": area(0, 14, 1, 2), "mapa": "estrada_caravanas", "spawn": "aldeia"}],
        renascer=["aldeia_tamareiras", "oeste"])


def vila_pescadores(Grid, register, area):
    g = Grid(44, 32)
    g.border("#")
    g.rect(0, 22, 44, 10, "W")
    g.vline(0, 14, 15, ":")
    g.hline(0, 42, 14, ":", 2)
    g.hline(2, 41, 20, ":")
    # Píer que entra no mar.
    g.rect(30, 21, 2, 8, "=")
    # Casas.
    g.house(3, 6, 7, door=3, windows=(1, 5))
    g.house(14, 6, 7, door=3, windows=(1, 5))
    g.house(25, 6, 8, door=4, windows=(1, 6))
    g.house(35, 6, 6, door=2, windows=(4,))
    g.stall(10, 17, 3)
    g.put(14, 17, "K"); g.put(15, 17, "K"); g.put(22, 17, "K")
    for x in range(4, 42, 6):
        if x not in (28,):
            g.put(x, 11, "T")
    register("vila_pescadores", g,
        nome="Vila dos Pescadores",
        moeda="perolas",
        spawns={"oeste": [1, 14]},
        npcs=[{"id": "lar_x_tome", "pos": [29, 19]}, {"id": "lar_x_iara", "pos": [11, 16]},
              {"id": "lar_x_marina", "pos": [36, 16]}, {"id": "lar_x_lino", "pos": [19, 18]},
              {"id": "lar_x_menino_nadador", "nada": True, "pos": [12, 25], "vagar": True},
              {"id": "lar_x_menina_nadadora", "nada": True, "pos": [22, 26], "vagar": True}],
        inimigos=[{"tipo": "caranguejo", "qtd": 4, "area": area(2, 21, 26, 1), "se": {"quest": "x_redes", "estado": "ativa"}}],
        placas=[{"pos": [2, 12], "texto": "Vila dos Pescadores. Oeste: Porto Coral."}],
        saidas=[{"area": area(0, 14, 1, 2), "mapa": "porto_coral", "spawn": "vila"}],
        renascer=["vila_pescadores", "oeste"])


def caverna_zazu(Grid, register, area):
    g = Grid(20, 14, "X")
    g.carve(3, 2, 14, 10)
    g.carve(9, 12, 2, 2)
    g.rect(7, 4, 6, 3, "P")
    g.put(4, 2, "E"); g.put(5, 2, "E"); g.put(15, 2, "E")
    g.put(4, 10, "h")
    g.put(15, 9, "m")
    register("caverna_zazu", g,
        nome="Caverna do Eremita",
        moeda="brasas",
        sem_montaria=True,
        spawns={"entrada": [9, 11]},
        npcs=[{"id": "lar_x_zazu", "pos": [10, 5]}],
        placas=[{"pos": [12, 2], "texto": "Gravado na pedra, em letras antigas: \"CONHEÇA A TI MESMO.\""}],
        saidas=[{"area": area(9, 13, 2, 1), "mapa": "dunas_rubras", "spawn": "zazu"}],
        renascer=["dunas_rubras", "zazu"])


# ---------------------------------------------------------------------
# Gente de fora das casas (NPCs das áreas novas). Ids com "lar_" para casas.py refazer sem duplicar.
# ---------------------------------------------------------------------

def gente_de_fora():
    morador("lar_x_sadiq", "Mestre Sadiq", ap("turbante", "tunica", h="#d0d0d0", b="#7a3a2a", a="#e0b040", barba=True), [
        f("lar_x_sadiq_fim", {"quest": "x_treino", "estado": "pronta"}, importante=True),
        f("lar_x_sadiq_oi", {"quest": "x_treino", "estado": "nao_iniciada"}, importante=True),
        f("lar_x_sadiq_menu")])
    d("lar_x_sadiq_oi", "Mestre Sadiq: Então você é o filho de Samira. Tem os ombros do pai, mas a teimosia é dela.",
      "Mestre Sadiq: Antes de enfrentar o deserto, quebre três bonecos. Quero ver esse braço.",
      escolhas=[esc("Pode deixar, mestre.", [{"quest_iniciar": "x_treino"}]), esc("Depois.")])
    d("lar_x_sadiq_fim", "Mestre Sadiq: Bom golpe! Lembre: quem acerta enche a Fúria. Quem enche a Fúria vira fogo.",
      acoes=[{"quest_concluir": "x_treino"}])
    d("lar_x_sadiq_menu", "Mestre Sadiq: O que vai ser, aprendiz?",
      escolhas=[esc("Quero o desafio da arena.", [{"quest_iniciar": "x_arena"}, {"arena": 1}], "lar_x_sadiq_arena"),
                esc("Me dê uma dica.", ir="lar_x_sadiq_dica"),
                esc("Até mais.")])
    d("lar_x_sadiq_arena", "Mestre Sadiq: Entre no cercado da arena! Três ondas. Se cair, ninguém vai rir... muito.")
    d("lar_x_sadiq_dica", "Mestre Sadiq: Empurre um inimigo contra a parede e ele fica tonto. Empurre contra outro e os dois rolam.",
      "Mestre Sadiq: E dizem que nas Dunas Rubras há uma pedra que nenhum homem move. Bobagem... ou não.")
    morador("lar_x_aprendiz", "Nina, aprendiz", ap("longo", "tunica", h="#3a1a10", b="#5a7a3a"), [f("lar_x_aprendiz")])
    d("lar_x_aprendiz", "Nina: Eu já quebrei quarenta bonecos hoje! O mestre diz que não conta se eu chutar.")

    # Aldeia das Tamareiras.
    morador("lar_x_salma", "Salma, a fazendeira", ap("veu", "manto", b="#6a8a3a", a="#e0c060"), [
        f("lar_x_salma_fim", {"quest": "x_hienas", "estado": "pronta"}, importante=True),
        f("lar_x_salma_pede", {"quest": "x_hienas", "estado": "nao_iniciada"}, importante=True),
        f("lar_x_salma_lembra", {"quest": "x_hienas", "estado": "ativa"}),
        f("lar_x_salma_padrao")])
    d("lar_x_salma_pede", "Salma: Hienas! Toda noite elas descem no pomar e levam as tâmaras.",
      "Salma: Pode espantar umas quatro? A aldeia inteira agradece.",
      escolhas=[esc("Deixa comigo.", [{"quest_iniciar": "x_hienas"}]), esc("Agora não.")])
    d("lar_x_salma_lembra", "Salma: Elas ficam no pomar, depois do canal. Cuidado com o bote delas!")
    d("lar_x_salma_fim", "Salma: O pomar está em paz! Leve carne seca: dizem que uma hiena cansada aceita até virar montaria.",
      acoes=[{"quest_concluir": "x_hienas"}])
    d("lar_x_salma_padrao", "Salma: As tâmaras deste ano estão doces como mel.")
    morador("lar_x_badu", "Tio Badu", ap("turbante", "tunica", b="#a06a3a", a="#5a3a2a", barba=True), [f("lar_x_badu")])
    d("lar_x_badu", "Tio Badu: Tâmaras, pão e carne seca! Tudo da aldeia.",
      escolhas=[esc("Comprar ou vender", [{"loja": "mercado_tamareiras"}]), esc("Até mais")])
    morador("lar_x_zuleica", "Vó Zuleica", ap("veu", "manto", h="#e0e0e0", b="#4a3a6a", a="#c0a0e0"), [f("lar_x_zuleica")])
    d("lar_x_zuleica", "Vó Zuleica: Já ouviu falar de Zazu? O eremita das Dunas Rubras.",
      "Vó Zuleica: Dizem que ele mora atrás de uma pedra que nenhum homem move. Mas pedra não é homem... pedra rola.",
      "Vó Zuleica: Procure onde três palmeiras se curvam diante de um paredão.")
    morador("lar_x_safira", "Dona Safira", ap("longo", "manto", h="#2a1a10", b="#8a3a5a"), [f("lar_x_safira")])
    d("lar_x_safira", "Dona Safira: Casa de hóspedes da aldeia! Uma noite custa 6 Brasas.",
      escolhas=[esc("Dormir (6 Brasas)", [{"pagar": "brasas", "qtd": 6}, {"dormir": True}, {"salvar": True}], se={"moeda": {"brasas": 6}}),
                esc("Não, obrigado")])
    morador("lar_x_tico", "Tico", ap("curto", crianca=True, b="#d0a040"), [f("lar_x_tico")])
    d("lar_x_tico", "Tico: Eu nado no canal todo dia! Meu irmão diz que tem peixe-gato lá. Mentira dele.")
    morador("lar_x_nadador_canal", "Rafi", ap("curto", crianca=True, h="#1a1008", b="#3a7aa0"), [f("lar_x_nadador_canal")])
    d("lar_x_nadador_canal", "Rafi: *glub* A água tá fresquinha! Pula aqui, guardião!")

    # Vila dos Pescadores.
    morador("lar_x_tome", "Seu Tomé", ap("turbante", "tunica", h="#c0c0c0", b="#3a5a8a", a="#e0d0a0", barba=True), [
        f("lar_x_tome_fim", {"quest": "x_redes", "estado": "pronta"}, importante=True),
        f("lar_x_tome_pede", {"quest": "x_redes", "estado": "nao_iniciada"}, importante=True),
        f("lar_x_tome_lembra", {"quest": "x_redes", "estado": "ativa"}),
        f("lar_x_tome_padrao")])
    d("lar_x_tome_pede", "Seu Tomé: Os caranguejos da praia cortaram minhas redes de novo! Quarenta anos de mar e nunca vi tanto.",
      "Seu Tomé: Dá uma limpada na praia pra mim? Uns cinco já resolvem.",
      escolhas=[esc("Vou lá.", [{"quest_iniciar": "x_redes"}]), esc("Agora não.")])
    d("lar_x_tome_lembra", "Seu Tomé: Na beira da água, perto do píer. Eles beliscam forte!")
    d("lar_x_tome_fim", "Seu Tomé: Praia limpa! Toma, as pérolas que as redes me deram este mês.",
      acoes=[{"quest_concluir": "x_redes"}])
    d("lar_x_tome_padrao", "Seu Tomé: O mar dá e o mar toma. Hoje deu.")
    morador("lar_x_iara", "Iara", ap("longo", "tunica", h="#1a0a05", b="#2a8a8a"), [f("lar_x_iara")])
    d("lar_x_iara", "Iara: Peixe fresco, poções e carne seca pra viagem!",
      escolhas=[esc("Comprar ou vender", [{"loja": "mercado_pescadores"}]), esc("Até mais")])
    morador("lar_x_marina", "Marina, da pousada", ap("veu", "manto", b="#3a6aa0", a="#e0e0e0"), [f("lar_x_marina")])
    d("lar_x_marina", "Marina: A Pousada da Maré tem rede de dormir e barulho de onda. Uma noite: 3 Pérolas.",
      escolhas=[esc("Dormir (3 Pérolas)", [{"pagar": "perolas", "qtd": 3}, {"dormir": True}, {"salvar": True}], se={"moeda": {"perolas": 3}}),
                esc("Não, obrigado")])
    morador("lar_x_lino", "Velho Lino", ap("curto", "tunica", h="#d0d0d0", b="#6a5a4a", barba=True), [f("lar_x_lino")])
    d("lar_x_lino", "Velho Lino: Quando eu era moço, conheci um eremita chamado Zazu. Fazia perguntas que ninguém sabia responder.",
      "Velho Lino: Ele vivia nas Dunas Rubras, numa caverna tapada por uma pedra redonda. Basta empurrar de lado, ele dizia.")
    morador("lar_x_menino_nadador", "Caio", ap("curto", crianca=True, h="#3a2010", b="#e0a040"), [f("lar_x_menino_nadador")])
    d("lar_x_menino_nadador", "Caio: Aposto que eu nado até o píer antes de você!")
    morador("lar_x_menina_nadadora", "Lia", ap("longo", crianca=True, h="#5a2a10", b="#e06080"), [f("lar_x_menina_nadadora")])
    d("lar_x_menina_nadadora", "Lia: Minha mãe disse que no fundo do mar mora uma cidade de vidro. Um dia eu acho.")

    # Gente que nada nas cidades antigas também.
    morador("lar_x_banhista_miraj", "Zara, a banhista", ap("longo", "tunica", h="#2a1008", b="#a04060"), [f("lar_x_banhista_miraj")])
    d("lar_x_banhista_miraj", "Zara: A água do lago voltou a ser limpa! Ninguém me tira daqui hoje.")
    morador("lar_x_nadador_coral", "Duda Júnior", ap("curto", crianca=True, h="#1a0a05", b="#40a0c0"), [f("lar_x_nadador_coral")])
    d("lar_x_nadador_coral", "Duda Júnior: Meu pai é ferreiro, mas eu vou ser mergulhador de pérolas!")

    # O segredo: Ancião Zazu.
    morador("lar_x_zazu", "Ancião Zazu", ap("longo", "manto", h="#f0f0f0", b="#5a3a9a", a="#e0c060", barba=True), [
        f("lar_x_zazu_oitavo", [{"flag": "oitavo_fogo"}, {"flag": "zazu_sabio"}], importante=True),
        f("lar_x_zazu_depois", {"flag": "zazu_sabio"}),
        f("lar_x_zazu_oi", importante=True)])
    d("lar_x_zazu_oi", "Ancião Zazu: Hm. Faz trinta anos que ninguém rola aquela pedra. Você tem braço... e paciência.",
      "Ancião Zazu: Eu sou Zazu. Respondo quem me responde. Três perguntas e uma quarta.",
      "Ancião Zazu: Primeira. O que é que, quanto mais se tira, maior fica?",
      escolhas=[esc("A sombra.", ir="lar_x_zazu_erro"), esc("Um buraco.", ir="lar_x_zazu_2"), esc("O deserto.", ir="lar_x_zazu_erro")])
    d("lar_x_zazu_2", "Ancião Zazu: Hm-hm. Segunda. Tenho cidades sem casas, rios sem água e desertos sem areia. O que sou?",
      escolhas=[esc("Um sonho.", ir="lar_x_zazu_erro"), esc("Uma lenda.", ir="lar_x_zazu_erro"), esc("Um mapa.", ir="lar_x_zazu_3")])
    d("lar_x_zazu_3", "Ancião Zazu: Terceira. Corro sem pernas, uivo sem boca, todos me ouvem e ninguém me vê.",
      escolhas=[esc("O vento.", ir="lar_x_zazu_4"), esc("Um fantasma.", ir="lar_x_zazu_erro"), esc("O eco.", ir="lar_x_zazu_erro")])
    d("lar_x_zazu_4", "Ancião Zazu: Agora a quarta, a única que importa. Quem é você?",
      escolhas=[esc("Ifrit, filho de Samira.", ir="lar_x_zazu_fim"),
                esc("Um guardião da Chama.", ir="lar_x_zazu_fim"),
                esc("Ainda estou descobrindo.", [{"honra": 5}], "lar_x_zazu_sabio")])
    d("lar_x_zazu_erro", "Ancião Zazu: Não. Volte quando a resposta morar em você, não na sua boca.")
    d("lar_x_zazu_fim", "Ancião Zazu: É o que dizem de você. Mas não foi isso que perguntei.",
      "Ancião Zazu: Leia a parede quando sair. E leve isto: um olho que vê o fogo antes de ele nascer.",
      acoes=[{"flag": "zazu_sabio"}, {"dar_item": "olho_zazu", "qtd": 1}, {"segredo": "zazu"}])
    d("lar_x_zazu_sabio", "Ancião Zazu: ...Ha! Finalmente alguém honesto. \"Conheça a ti mesmo\", diziam os antigos no templo deles.",
      "Ancião Zazu: Leve isto: um olho que vê o fogo antes de ele nascer. Sua Fúria vai acender mais rápido.",
      acoes=[{"flag": "zazu_sabio"}, {"dar_item": "olho_zazu", "qtd": 1}, {"segredo": "zazu"}])
    d("lar_x_zazu_depois", "Ancião Zazu: Sete chamas, Ifrit. Todos contam sete.",
      "Ancião Zazu: Mas quem acendeu a primeira? Um dia, pergunte à sua mãe sobre o oitavo fogo.")
    d("lar_x_zazu_oitavo", "Ancião Zazu: Ele acordou. Eu avisei sobre o oitavo fogo.",
      "Ancião Zazu: Agora você entende por que eu moro atrás de uma pedra.")

    segredos_e_pos_jogo()


def _objeto(nid, nome, sprite, falas):
    """Objeto que se lê como um NPC (placa, bilhete, livro): pode rodar ações, ao contrário das placas do mapa."""
    NPCS[nid] = {"nome": nome, "sprite": sprite, "falas": falas}
    return nid


def segredos_e_pos_jogo():
    # Segredos e homenagens (lista em data/segredos.json; a ação "segredo" conta cada um uma vez).
    morador("lar_x_velho_canion", "Velho da Gruta", ap("longo", "manto", h="#f0f0f0", b="#7a2a2a", a="#d0a040", barba=True), [
        f("lar_x_velho_canion_depois", {"flag": "velho_canion_presente"}),
        f("lar_x_velho_canion")])
    d("lar_x_velho_canion", "Velho da Gruta: É perigoso ir sozinho! Leve isto.",
      acoes=[{"dar_item": "pocao_media", "qtd": 2}, {"flag": "velho_canion_presente"}, {"segredo": "sozinho"}])
    d("lar_x_velho_canion_depois", "Velho da Gruta: Já te dei tudo o que eu tinha. Dizem que antigamente eu dava espadas.",
      "Velho da Gruta: Bons tempos. Agora vá, e não conte a ninguém sobre este canto.")

    _objeto("lar_x_placa_bolo", "Placa enferrujada", "res://assets/placa.png", [f("lar_x_placa_bolo")])
    d("lar_x_placa_bolo", "Uma placa enferrujada, pregada entre as engrenagens:",
      "\"PARABÉNS, OPERÁRIO. AO FIM DO TURNO HAVERÁ BOLO PARA TODOS.\"",
      "Embaixo, alguém riscou com a ponta de uma faca: \"O bolo é uma mentira.\"",
      acoes=[{"segredo": "bolo"}])

    morador("lar_x_sabio_qadim", "Sábio Pensador", ap("careca", "manto", h="#e0e0e0", b="#3a5a8a", a="#e0c060", barba=True), [
        f("lar_x_sabio_qadim")])
    d("lar_x_sabio_qadim", "Sábio Pensador: Passei sete milhões e meio de... bem, muitos anos pensando na Grande Pergunta.",
      "Sábio Pensador: A resposta para a vida, o universo e tudo mais é... quarenta e dois.",
      "Ifrit: Quarenta e dois? E qual é a pergunta?",
      "Sábio Pensador: Isso eu ainda estou calculando. Mas não entre em pânico.",
      acoes=[{"segredo": "quarenta_e_dois"}])

    morador("lar_x_cavaleiro_sol", "Cavaleiro do Sol", ap("curto", "armadura", h="#c08040", b="#d0a020", a="#e0e0e0"), [
        f("lar_x_cavaleiro_sol")])
    d("lar_x_cavaleiro_sol", "Cavaleiro do Sol: Ah, um viajante! Já viu o sol daqui de cima? Glorioso!",
      "Cavaleiro do Sol: Se um dia a sua chama vacilar, faça como eu. Braços para o alto e... LOUVADO SEJA O SOL!",
      "Ele ergue os braços em V, imóvel e radiante. Você sente uma vontade estranha de fazer o mesmo.",
      acoes=[{"segredo": "sol"}])

    morador("lar_x_prisioneiro", "Prisioneiro", ap("curto", "tunica", h="#5a4a3a", b="#6a6a6a", barba=True), [
        f("lar_x_prisioneiro")])
    d("lar_x_prisioneiro", "Prisioneiro: O General caiu? Estou livre!",
      "Prisioneiro: Obrigado, Ifrit! Mas sua princesa está em outro castelo.",
      "Ifrit: ...Que princesa?",
      acoes=[{"segredo": "castelo"}])

    _objeto("lar_x_placa_calango", "Placa torta", "res://assets/placa.png", [f("lar_x_placa_calango")])
    d("lar_x_placa_calango", "Alguém rabiscou na placa, com letra de criança:",
      "\"Um CALANGO selvagem apareceu!\"",
      "Embaixo, o desenho de um menino diante de um calango e quatro quadradinhos com as palavras LUTAR, BOLSA, TROCAR e FUGIR.",
      acoes=[{"segredo": "calango"}])

    morador("lar_x_pescador_velho", "Vô Arnaldo", ap("turbante", "tunica", h="#e0e0e0", b="#3a6a5a", a="#d0c090", barba=True), [
        f("lar_x_pescador_velho")])
    d("lar_x_pescador_velho", "Vô Arnaldo: Ah, menino... no meu tempo o mundo era clássico.",
      "Vô Arnaldo: Todo mundo cortava arbustos atrás de moedinhas e jogava bombas em parede rachada procurando passagem secreta. E ninguém achava estranho!",
      "Vô Arnaldo: Hoje vocês empurram pedras. Hmpf. Bom... também vale.",
      acoes=[{"segredo": "classico"}])

    # Pós-jogo (ganchos do final): bilhete na casa de Harun e o diário no Trono Cinzento.
    # Os diálogos "harun_pos_jogo" e "diario_zahrak" ficam em data/dialogos/final.json.
    _objeto("lar_x_bilhete_harun", "Bilhete de Harun", "res://assets/itens/carta.png",
            [f("harun_pos_jogo", importante=True)])
    _objeto("lar_x_diario_zahrak", "Diário de Zahrak", "res://assets/livro.png", [f("diario_zahrak")])


# ---------------------------------------------------------------------
# Moradores das casas das vilas (casas.py usa na ordem das portas).
# ---------------------------------------------------------------------

def aldeia_casas():
    gente_de_fora()
    yield [(morador("lar_x_hasna", "Hasna", ap("veu", "manto", b="#8a6a3a", a="#e0c060"), [f("lar_x_hasna")]), (3, 3))]
    d("lar_x_hasna", "Hasna: Colhemos tâmaras desde antes do nascer do sol. Quer uma? Pegue duas!",
      acoes=[{"dar_item": "tamara", "qtd": 1}])
    yield [(morador("lar_x_jabir", "Jabir", ap("turbante", "tunica", b="#5a4a2a", barba=True), [f("lar_x_jabir")]), (4, 3))]
    d("lar_x_jabir", "Jabir: O canal foi ideia do meu avô. Antes dele, a aldeia era só areia e saudade.")
    yield [(morador("lar_x_kenza", "Kenza", ap("longo", crianca=True, h="#2a1008", b="#c06040"), [f("lar_x_kenza")]), (8, 4))]
    d("lar_x_kenza", "Kenza: Você é o guardião? Mostra a bola de fogo! Só uma!")


def vila_casas():
    yield [(morador("lar_x_quito", "Quito", ap("curto", "tunica", h="#1a1008", b="#2a5a8a", barba=True), [f("lar_x_quito")]), (3, 3))]
    d("lar_x_quito", "Quito: Remendo redes desde menino. Os caranguejos sabem disso e me dão serviço.")
    yield [(morador("lar_x_celeste", "Celeste", ap("veu", "manto", b="#3a8aa0", a="#f0f0f0"), [f("lar_x_celeste")]), (8, 4))]
    d("lar_x_celeste", "Celeste: Meu marido saiu no barco do Kraal e nunca voltou. Obrigada por afundar aquele navio.")
    yield [(morador("lar_x_bento", "Bento", ap("turbante", "tunica", b="#6a4a3a", a="#d0b080"), [f("lar_x_bento")]), (3, 3))]
    d("lar_x_bento", "Bento: Já viu as conchas que brilham à noite? Minha filha jura que falam.")
    yield [(morador("lar_x_vovo_ana", "Vó Ana", ap("veu", "manto", h="#e0e0e0", b="#7a5a8a"), [f("lar_x_vovo_ana")]), (4, 3))]
    d("lar_x_vovo_ana", "Vó Ana: Senta, menino. Toma um chá de alga. Faz bem pro juízo.",
      escolhas=[esc("Aceitar o chá.", [{"curar": True}], "lar_x_vovo_cha"), esc("Fica pra próxima, vó.")])
    d("lar_x_vovo_cha", "O chá é estranho, mas você se sente bem melhor.")


# ---------------------------------------------------------------------
# Cidades organizadas: calçada de cada porta até a rua, árvores em fileiras, flores nos jardins.
# ---------------------------------------------------------------------

def _pontos(data):
    pts = set()
    for v in data.get("spawns", {}).values():
        pts.add(tuple(v))
    for k in ("npcs", "baus", "placas", "coletaveis", "empurraveis"):
        for e in data.get(k, []):
            if not e.get("nada"):
                pts.add(tuple(e["pos"]))
    for w in data.get("saidas", []):
        x, y, ww, hh = w["area"]
        for xx in range(x, x + ww):
            for yy in range(y, y + hh):
                pts.add((xx, yy))
    return pts


def _alcanca(rows, start, alvos):
    h, w = len(rows), len(rows[0])
    seen = {start}
    q = deque([start])
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and (rows[ny][nx] not in SOLID or (nx, ny) in alvos):
                seen.add((nx, ny))
                q.append((nx, ny))
    return all(a in seen for a in alvos)


def _calcada(rows, door):
    """Caminho mais curto da frente da porta até a rua (':' ou ponte), passando só por chão."""
    h, w = len(rows), len(rows[0])
    sx, sy = door[0], door[1] + 1
    if not (0 <= sy < h) or rows[sy][sx] in SOLID:
        return
    prev = {(sx, sy): None}
    q = deque([(sx, sy)])
    end = None
    while q:
        x, y = q.popleft()
        if rows[y][x] in ":=" and (x, y) != (sx, sy):
            end = (x, y)
            break
        for dx, dy in ((0, 1), (1, 0), (-1, 0), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 < nx < w - 1 and 0 < ny < h - 1 and (nx, ny) not in prev and rows[ny][nx] not in SOLID:
                prev[(nx, ny)] = (x, y)
                q.append((nx, ny))
    if end is None:
        return
    p = prev[end]
    while p is not None:
        if rows[p[1]][p[0]] in ".,*":
            rows[p[1]][p[0]] = ":"
        p = prev[p]


def _chao_local(rows, x, y, padrao):
    viz = [rows[y + dy][x + dx] for dx in (-1, 0, 1) for dy in (-1, 0, 1)
           if 0 <= y + dy < len(rows) and 0 <= x + dx < len(rows[0]) and rows[y + dy][x + dx] in ".,"]
    return max(set(viz), key=viz.count) if viz else padrao


def urbanizar(data, arvore="T", limpar=True):
    rows = _rows(data)
    h, w = len(rows), len(rows[0])
    pts = _pontos(data)
    chao = max(".,", key=lambda c: sum(r.count(c) for r in rows))
    # 1) Tira árvores, cactos e pedras jogados ao acaso (menos as palmeiras em volta da água).
    if limpar:
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if rows[y][x] in "TCr":
                    agua = any(rows[y + dy][x + dx] == "W" for dx in (-1, 0, 1) for dy in (-1, 0, 1))
                    if not agua:
                        rows[y][x] = _chao_local(rows, x, y, chao)
    # 2) Calçada de cada porta até a rua.
    portas = [(x, y) for y in range(h) for x in range(w) if rows[y][x] == "D"]
    for p in portas:
        _calcada(rows, p)
    # 3) Flores dos dois lados da entrada.
    for x, y in portas:
        for dx in (-1, 1):
            if 0 <= y + 1 < h and rows[y + 1][x + dx] in ".," and (x + dx, y + 1) not in pts:
                rows[y + 1][x + dx] = "*"
    # 4) Árvores alinhadas dos dois lados das ruas principais (largura 2), a cada 4 tiles.
    inicio = tuple(next(iter(data["spawns"].values())))
    alvos = pts | {(x, y + 1) for x, y in portas}
    candidatos = []
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            if rows[y][x] != ":":
                continue
            if rows[y][x - 1] == ":" and rows[y][x + 1] == ":" and x % 4 == 0:
                if rows[y - 1][x] != ":":
                    candidatos.append((x, y - 2))
                if rows[y + 1][x] != ":":
                    candidatos.append((x, y + 2))
            if rows[y - 1][x] == ":" and rows[y + 1][x] == ":" and y % 4 == 0:
                if rows[y][x - 1] != ":":
                    candidatos.append((x - 2, y))
                if rows[y][x + 1] != ":":
                    candidatos.append((x + 2, y))
    for x, y in candidatos:
        if not (1 < x < w - 2 and 1 < y < h - 2) or rows[y][x] not in ".,":
            continue
        viz = [rows[y + dy][x + dx] for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx, dy) != (0, 0)]
        if any((c in SOLID and c != "T") or c == "D" for c in viz) or sum(c == ":" for c in viz) > 3:
            continue
        if any(abs(x - px) <= 1 and abs(y - py) <= 1 for px, py in alvos):
            continue
        antes = rows[y][x]
        rows[y][x] = arvore
        if not _alcanca(rows, inicio, alvos):
            rows[y][x] = antes
    _set_rows(data, rows)


def _mesclar(path, novos, chave=None):
    with open(path, encoding="utf-8") as fh:
        atual = json.load(fh)
    alvo = atual[chave] if chave else atual
    alvo.update(novos)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(atual, fh, ensure_ascii=False, indent=1)


def build(Grid, register, area, MAPS):
    ligar_saidas(MAPS, area)
    for fn in (campo_treino, canion_feras, aldeia_tamareiras, vila_pescadores, caverna_zazu):
        fn(Grid, register, area)
    # Nadadores nas águas das cidades antigas.
    MAPS["oasis_miraj"]["npcs"].append({"id": "lar_x_banhista_miraj", "nada": True, "pos": [19, 18], "vagar": True})
    MAPS["porto_coral"]["npcs"].append({"id": "lar_x_nadador_coral", "nada": True, "pos": [20, 30], "vagar": True})
    # Segredos espalhados pelo mundo e o diário de Zahrak (só depois da luta final).
    for map_id, entry in SEGREDOS_NPCS:
        x, y = entry["pos"]
        assert MAPS[map_id]["layout"][y][x] not in SOLID, f"{map_id}: {entry['id']} em tile sólido"
        MAPS[map_id].setdefault("npcs", []).append(dict(entry))
    for city in casas.CIDADES:
        urbanizar(MAPS[city])
    for vila in VILAS:
        urbanizar(MAPS[vila], limpar=False)
    # As vilas ganham interiores e moradores pelo mesmo sistema das cidades.
    casas.CIDADES.update(VILAS)
    casas.CONTEUDO["aldeia_tamareiras"] = aldeia_casas
    casas.CONTEUDO["vila_pescadores"] = vila_casas
    _mesclar(os.path.join(DATA, "missoes.json"), MISSOES)
    _mesclar(os.path.join(DATA, "lojas.json"), LOJAS)
    _mesclar(os.path.join(DATA, "mundo.json"), REGIOES, "regioes")
    print("extras: campo de treino, cânion, 2 vilas, caverna do Zazu; cidades organizadas")
