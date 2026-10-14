"""Gera os sprites provisórios (pixel art 16x16) do protótipo.
Uso: python3 tools/gerar_sprites.py  (rodar na pasta game/)"""
from PIL import Image
import os, random

OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

def sprite(rows, palette, name):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((x, y), palette[ch])
    img.save(os.path.join(OUT, name))

# Ifrit: o herói (cabelo vermelho, faixa dourada, túnica)
sprite([
    "................",
    ".....rrrrr......",
    "....rrrrrrr.....",
    "....yyyyyyyy....",
    "....rssssssr....",
    "....sskssks.....",
    "....ssssssss....",
    ".....ssmmss.....",
    "....bbbbbbbb....",
    "...sbbyyyybbs...",
    "...sbbbbbbbbs...",
    "....bbbbbbbb....",
    "....ddd..ddd....",
    "....ddd..ddd....",
    "....kkk..kkk....",
    "................",
], {"r": (200, 40, 30, 255), "y": (240, 190, 60, 255), "s": (230, 170, 120, 255),
    "k": (40, 25, 20, 255), "m": (170, 90, 70, 255), "b": (40, 90, 170, 255),
    "d": (90, 60, 40, 255)}, "ifrit.png")

# Escorpião do deserto
sprite([
    "................",
    ".........bb.....",
    "........b..b....",
    "...........b....",
    "..........b.....",
    ".........b......",
    "..bb....bb...bb.",
    ".b..bbbbbbbbb..b",
    "....bBBBBBBBb...",
    "...bBBkBBkBBBb..",
    "...bBBBBBBBBBb..",
    "....bBBBBBBBb...",
    "...b.b.b.b.b.b..",
    "..b..b..b..b..b.",
    "................",
    "................",
], {"b": (90, 50, 20, 255), "B": (170, 110, 50, 255), "k": (20, 10, 5, 255)}, "escorpiao.png")

# Brasa (moeda)
sprite([
    "................",
    "................",
    "................",
    "................",
    "......oo........",
    ".....oyyo.......",
    "....oyyyyo......",
    "....oyyyyo......",
    ".....oyyo.......",
    "......oo........",
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
], {"o": (230, 90, 20, 255), "y": (255, 210, 70, 255)}, "brasa.png")

# Bola de fogo
sprite([
    "................",
    "................",
    "................",
    "................",
    "......oooo......",
    ".....orrrro.....",
    "....oryyyyro....",
    "....oryyyyro....",
    "....oryyyyro....",
    "....oryyyyro....",
    ".....orrrro.....",
    "......oooo......",
    "................",
    "................",
    "................",
    "................",
], {"o": (200, 40, 20, 180), "r": (255, 120, 30, 255), "y": (255, 240, 150, 255)}, "bola_de_fogo.png")

# Rocha
sprite([
    "................",
    "................",
    ".....kkkkk......",
    "....kGGGGGk.....",
    "...kGgggGGGk....",
    "..kGggggggGGk...",
    "..kGggggggggk...",
    ".kGgggggggggGk..",
    ".kGgggggggggGk..",
    ".kggggggggggGk..",
    ".kggggggggggk...",
    "..kgggggggggk...",
    "...kkgggggkk....",
    ".....kkkkk......",
    "................",
    "................",
], {"k": (60, 50, 50, 255), "G": (160, 150, 140, 255), "g": (120, 110, 105, 255)}, "rocha.png")

# Areia (tile que repete)
random.seed(7)
img = Image.new("RGBA", (16, 16), (232, 196, 128, 255))
for _ in range(14):
    x, y = random.randrange(16), random.randrange(16)
    img.putpixel((x, y), random.choice([(214, 176, 110, 255), (245, 212, 150, 255)]))
img.save(os.path.join(OUT, "areia.png"))
print("ok")
