"""Gera o atlas de tiles 16x16 (assets/tiles.png) e sprites de objetos do modo história.
Uso: python3 tools/gerar_tiles.py  (rodar na pasta game/)
A ordem dos tiles precisa bater com TILE_CHARS em scripts/world/tile_layer.gd."""
from PIL import Image, ImageDraw
import os, random

OUT = os.path.join(os.path.dirname(__file__), "..", "assets")
T = 16
random.seed(3)

def noise(base, alts, n):
    img = Image.new("RGBA", (T, T), base)
    for _ in range(n):
        img.putpixel((random.randrange(T), random.randrange(T)), random.choice(alts))
    return img

def over(bg, fg_func):
    img = bg.copy()
    fg_func(ImageDraw.Draw(img), img)
    return img

SAND = (232, 196, 128, 255)
areia = noise(SAND, [(214, 176, 110, 255), (245, 212, 150, 255)], 14)
grama = noise((110, 160, 70, 255), [(90, 140, 55, 255), (130, 180, 85, 255)], 30)
caminho = noise((200, 160, 110, 255), [(185, 145, 95, 255), (215, 175, 125, 255)], 25)

def madeira_f():
    img = Image.new("RGBA", (T, T), (150, 100, 60, 255))
    d = ImageDraw.Draw(img)
    for y in (3, 7, 11, 15):
        d.line([(0, y), (15, y)], fill=(120, 78, 45, 255))
    d.point([(5, 1), (12, 5), (3, 9), (9, 13)], fill=(120, 78, 45, 255))
    return img
madeira = madeira_f()
caverna = noise((95, 80, 75, 255), [(80, 66, 62, 255), (110, 95, 88, 255)], 30)

def muro_f():
    img = Image.new("RGBA", (T, T), (150, 140, 130, 255))
    d = ImageDraw.Draw(img)
    for y in (0, 5, 10, 15):
        d.line([(0, y), (15, y)], fill=(100, 92, 86, 255))
    for y, off in ((1, 0), (6, 4), (11, 0)):
        for x in range(off, 16, 8):
            d.line([(x, y), (x, y + 3)], fill=(100, 92, 86, 255))
    return img
muro = muro_f()

def adobe_f(janela=False):
    img = noise((210, 160, 110, 255), [(195, 145, 95, 255)], 12)
    d = ImageDraw.Draw(img)
    d.line([(0, 15), (15, 15)], fill=(160, 115, 75, 255))
    if janela:
        d.rectangle([4, 4, 11, 10], fill=(60, 80, 110, 255), outline=(110, 70, 40, 255))
        d.line([(8, 4), (8, 10)], fill=(110, 70, 40, 255))
    return img
adobe = adobe_f()
janela = adobe_f(True)

def telhado_f():
    img = Image.new("RGBA", (T, T), (170, 70, 50, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, 16, 4):
        d.line([(0, y), (15, y)], fill=(130, 50, 35, 255))
        for x in range((y // 4 % 2) * 4, 16, 8):
            d.point((x, y + 2), fill=(130, 50, 35, 255))
    return img
telhado = telhado_f()

def palmeira(d, img):
    d.rectangle([7, 7, 8, 15], fill=(130, 90, 50, 255))
    d.ellipse([1, 1, 14, 9], fill=(60, 140, 60, 255))
    d.line([(1, 6), (5, 3)], fill=(40, 110, 45, 255))
    d.line([(14, 6), (10, 3)], fill=(40, 110, 45, 255))
    d.point([(6, 5), (9, 5)], fill=(150, 100, 40, 255))
arvore = over(areia, palmeira)

def agua_f():
    img = Image.new("RGBA", (T, T), (60, 130, 200, 255))
    d = ImageDraw.Draw(img)
    d.line([(2, 4), (6, 4)], fill=(140, 200, 240, 255))
    d.line([(9, 10), (13, 10)], fill=(140, 200, 240, 255))
    return img
agua = agua_f()

def rocha(d, img):
    d.ellipse([1, 3, 14, 14], fill=(120, 110, 105, 255), outline=(60, 50, 50, 255))
    d.arc([3, 4, 10, 10], 180, 270, fill=(170, 160, 150, 255))
pedra = over(areia, rocha)

def mesa(d, img):
    d.rectangle([1, 4, 14, 11], fill=(110, 70, 40, 255), outline=(70, 45, 25, 255))
    d.rectangle([2, 12, 3, 15], fill=(70, 45, 25, 255))
    d.rectangle([12, 12, 13, 15], fill=(70, 45, 25, 255))
    d.ellipse([5, 5, 9, 8], fill=(230, 230, 220, 255))
mesa_t = over(madeira, mesa)

def cama(d, img):
    d.rectangle([1, 0, 14, 15], fill=(110, 70, 40, 255))
    d.rectangle([2, 1, 13, 4], fill=(240, 240, 235, 255))
    d.rectangle([2, 5, 13, 14], fill=(170, 50, 60, 255))
cama_t = over(madeira, cama)

def porta(d, img):
    d.rectangle([2, 0, 13, 15], fill=(100, 60, 30, 255), outline=(60, 35, 15, 255))
    d.line([(8, 0), (8, 15)], fill=(70, 40, 20, 255))
    d.point((11, 8), fill=(230, 200, 80, 255))
porta_t = over(adobe, porta)

def parede_caverna_f():
    img = noise((60, 48, 45, 255), [(45, 35, 33, 255), (75, 62, 58, 255)], 40)
    return img
parede_caverna = parede_caverna_f()

def cacto(d, img):
    d.rectangle([6, 2, 9, 15], fill=(60, 150, 70, 255))
    d.rectangle([2, 6, 4, 10], fill=(60, 150, 70, 255))
    d.rectangle([4, 9, 6, 10], fill=(60, 150, 70, 255))
    d.rectangle([11, 4, 13, 8], fill=(60, 150, 70, 255))
    d.rectangle([9, 7, 11, 8], fill=(60, 150, 70, 255))
    d.point([(7, 4), (8, 8), (7, 12)], fill=(30, 100, 40, 255))
cacto_t = over(areia, cacto)

def barraca(d, img):
    d.rectangle([0, 6, 15, 15], fill=(140, 95, 55, 255), outline=(90, 60, 30, 255))
    for x in range(0, 16, 4):
        d.rectangle([x, 0, x + 1, 5], fill=(200, 50, 50, 255))
        d.rectangle([x + 2, 0, x + 3, 5], fill=(240, 230, 210, 255))
    d.ellipse([3, 8, 6, 11], fill=(230, 140, 40, 255))
    d.ellipse([9, 8, 12, 11], fill=(120, 180, 60, 255))
barraca_t = over(areia, barraca)

vazio = Image.new("RGBA", (T, T), (10, 8, 12, 255))

def tapete(d, img):
    d.rectangle([0, 0, 15, 15], fill=(150, 40, 50, 255))
    d.rectangle([2, 2, 13, 13], outline=(230, 180, 60, 255))
    d.point((8, 8), fill=(230, 180, 60, 255))
tapete_t = over(madeira, tapete)

def caixote(d, img):
    d.rectangle([1, 2, 14, 15], fill=(170, 120, 70, 255), outline=(100, 65, 35, 255))
    d.line([(1, 2), (14, 15)], fill=(100, 65, 35, 255))
    d.line([(14, 2), (1, 15)], fill=(100, 65, 35, 255))
caixote_t = over(areia, caixote)

def parede_interna_f():
    img = Image.new("RGBA", (T, T), (180, 140, 100, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 11, 15, 15], fill=(120, 85, 55, 255))
    d.line([(0, 11), (15, 11)], fill=(90, 60, 35, 255))
    return img
parede_interna = parede_interna_f()

def portao(d, img):
    d.rectangle([0, 0, 15, 15], fill=(200, 160, 110, 255))
    d.line([(0, 0), (15, 0)], fill=(120, 110, 100, 255), width=2)
portao_t = over(caminho, portao)

def poco(d, img):
    d.ellipse([1, 3, 14, 15], fill=(140, 130, 120, 255), outline=(80, 70, 65, 255))
    d.ellipse([4, 6, 11, 12], fill=(30, 60, 110, 255))
poco_t = over(areia, poco)

def estante(d, img):
    d.rectangle([0, 0, 15, 15], fill=(100, 65, 35, 255))
    for y in (1, 6, 11):
        for x in range(1, 15, 2):
            d.rectangle([x, y, x, y + 3], fill=random.choice([(170, 40, 40, 255), (40, 90, 160, 255), (200, 170, 60, 255)]))
estante_t = over(madeira, estante)

def ponte_f():
    img = Image.new("RGBA", (T, T), (60, 130, 200, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 1, 15, 14], fill=(150, 105, 60, 255))
    for x in range(0, 16, 4):
        d.line([(x, 1), (x, 14)], fill=(110, 75, 40, 255))
    return img
ponte = ponte_f()

def flores(d, img):
    for x, y, c in ((3, 4, (230, 80, 90, 255)), (11, 3, (240, 220, 80, 255)), (7, 10, (230, 80, 90, 255)), (12, 12, (250, 250, 250, 255))):
        d.point([(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)], fill=c)
flores_t = over(grama, flores)

# Ordem = TILE_CHARS em tile_layer.gd
tiles = [areia, grama, caminho, madeira, caverna, muro, adobe, telhado, arvore, agua,
         pedra, mesa_t, cama_t, porta_t, parede_caverna, cacto_t, barraca_t, vazio,
         janela, tapete_t, caixote_t, parede_interna, portao_t, poco_t, estante_t, ponte, flores_t]
atlas = Image.new("RGBA", (T * len(tiles), T))
for i, t in enumerate(tiles):
    atlas.paste(t, (i * T, 0))
atlas.save(os.path.join(OUT, "tiles.png"))

# ---- Objetos e criaturas ----
def save(img, name):
    img.save(os.path.join(OUT, name))

def canvas(w=T, h=T):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)

img, d = canvas()
d.rectangle([2, 6, 13, 14], fill=(140, 90, 40, 255), outline=(70, 40, 20, 255))
d.rectangle([2, 4, 13, 7], fill=(160, 105, 50, 255), outline=(70, 40, 20, 255))
d.rectangle([7, 7, 8, 9], fill=(240, 200, 60, 255))
save(img, "bau.png")
img, d = canvas()
d.rectangle([2, 6, 13, 14], fill=(140, 90, 40, 255), outline=(70, 40, 20, 255))
d.rectangle([2, 2, 13, 4], fill=(160, 105, 50, 255), outline=(70, 40, 20, 255))
d.rectangle([3, 7, 12, 8], fill=(30, 20, 10, 255))
save(img, "bau_aberto.png")

img, d = canvas()
d.rectangle([7, 8, 8, 15], fill=(110, 70, 40, 255))
d.rectangle([2, 2, 13, 9], fill=(170, 120, 70, 255), outline=(100, 65, 35, 255))
d.line([(4, 5), (11, 5)], fill=(90, 60, 30, 255))
d.line([(4, 7), (9, 7)], fill=(90, 60, 30, 255))
save(img, "placa.png")

img, d = canvas()
d.line([(8, 15), (8, 7)], fill=(60, 120, 50, 255))
d.ellipse([3, 5, 8, 9], fill=(90, 170, 80, 255))
d.ellipse([8, 3, 13, 8], fill=(90, 170, 80, 255))
d.ellipse([6, 1, 10, 5], fill=(200, 120, 220, 255))
save(img, "erva.png")

img, d = canvas()
d.ellipse([3, 7, 13, 14], fill=(240, 150, 60, 255))
d.ellipse([2, 3, 9, 9], fill=(240, 150, 60, 255))
d.polygon([(2, 4), (3, 0), (5, 3)], fill=(240, 150, 60, 255))
d.polygon([(6, 3), (8, 0), (9, 4)], fill=(240, 150, 60, 255))
d.point([(4, 5), (7, 5)], fill=(20, 20, 20, 255))
d.line([(13, 12), (15, 7)], fill=(240, 150, 60, 255), width=2)
save(img, "gato.png")

# Cobra
img, d = canvas()
d.line([(2, 13), (5, 10), (9, 12), (12, 9)], fill=(90, 140, 50, 255), width=3)
d.ellipse([10, 4, 15, 9], fill=(110, 160, 60, 255))
d.point([(12, 6), (14, 6)], fill=(200, 30, 30, 255))
d.line([(15, 8), (15, 10)], fill=(220, 40, 60, 255))
save(img, "cobra.png")

# Morcego
img, d = canvas()
d.polygon([(8, 6), (0, 3), (2, 9), (5, 8)], fill=(70, 50, 90, 255))
d.polygon([(8, 6), (16, 3), (14, 9), (11, 8)], fill=(70, 50, 90, 255))
d.ellipse([5, 4, 11, 11], fill=(90, 65, 110, 255))
d.point([(7, 7), (9, 7)], fill=(250, 220, 60, 255))
save(img, "morcego.png")

# Rainha Escorpião (32x32)
base = Image.open(os.path.join(OUT, "escorpiao.png")).convert("RGBA").resize((32, 32), Image.NEAREST)
px = base.load()
for y in range(32):
    for x in range(32):
        r, g, b, a = px[x, y]
        if a:
            px[x, y] = (min(255, int(r * 1.3) + 40), int(g * 0.5), int(b * 0.9) + 40, a)
d = ImageDraw.Draw(base)
d.polygon([(10, 12), (12, 7), (14, 11), (16, 6), (18, 11), (20, 7), (22, 12)], fill=(240, 200, 60, 255))
save(base, "rainha_escorpiao.png")

# Fragmento da chama (item no mapa)
img, d = canvas()
d.polygon([(8, 1), (13, 8), (8, 15), (3, 8)], fill=(255, 140, 30, 255), outline=(200, 60, 20, 255))
d.polygon([(8, 5), (10, 8), (8, 11), (6, 8)], fill=(255, 240, 150, 255))
save(img, "fragmento.png")
print("ok", len(tiles), "tiles")

# Flecha (apontando para a direita)
img, d = canvas()
d.line([(2, 8), (12, 8)], fill=(120, 80, 40, 255), width=1)
d.polygon([(12, 6), (15, 8), (12, 10)], fill=(200, 200, 210, 255))
d.line([(2, 6), (4, 8)], fill=(230, 230, 230, 255))
d.line([(2, 10), (4, 8)], fill=(230, 230, 230, 255))
save(img, "flecha.png")

# Saco de item
img, d = canvas()
d.ellipse([3, 6, 12, 15], fill=(170, 130, 80, 255), outline=(100, 70, 40, 255))
d.rectangle([6, 3, 9, 6], fill=(150, 110, 65, 255))
d.line([(5, 6), (10, 6)], fill=(200, 60, 40, 255))
save(img, "saco.png")

# Pérola
img, d = canvas()
d.ellipse([4, 4, 11, 11], fill=(235, 235, 250, 255), outline=(160, 170, 200, 255))
d.point([(6, 6), (7, 6)], fill=(255, 255, 255, 255))
save(img, "perola.png")

# Coroa (moeda)
img, d = canvas()
d.ellipse([3, 3, 12, 12], fill=(230, 190, 60, 255), outline=(150, 110, 30, 255))
d.polygon([(5, 9), (5, 6), (6.5, 7.5), (8, 5), (9.5, 7.5), (11, 6), (11, 9)], fill=(150, 110, 30, 255))
save(img, "coroa.png")

# Poção
img, d = canvas()
d.rectangle([7, 2, 9, 5], fill=(200, 200, 210, 255))
d.ellipse([4, 5, 12, 14], fill=(220, 50, 70, 255), outline=(120, 30, 40, 255))
d.point([(6, 8)], fill=(255, 200, 200, 255))
save(img, "pocao.png")

# Carapaça
img, d = canvas()
d.ellipse([3, 4, 13, 13], fill=(170, 110, 50, 255), outline=(90, 50, 20, 255))
d.line([(4, 8), (12, 8)], fill=(90, 50, 20, 255))
d.line([(8, 4), (8, 13)], fill=(90, 50, 20, 255))
save(img, "carapaca.png")
print("ok extra")

# Chama Sagrada (braseiro)
img, d = canvas(16, 24)
d.rectangle([3, 16, 12, 23], fill=(120, 110, 100, 255), outline=(70, 60, 55, 255))
d.rectangle([2, 14, 13, 16], fill=(150, 140, 130, 255), outline=(70, 60, 55, 255))
d.polygon([(8, 1), (13, 10), (11, 14), (5, 14), (3, 10)], fill=(255, 130, 30, 255))
d.polygon([(8, 6), (10, 11), (8, 14), (6, 11)], fill=(255, 235, 140, 255))
save(img, "chama_sagrada.png")
img2 = img.copy()
px = img2.load()
for y in range(14):
    for x in range(16):
        r, g, b, a = px[x, y]
        if a:
            px[x, y] = (r // 2 + 40, g // 2 + 30, b // 2 + 40, a)
save(img2, "chama_fraca.png")

# Veneno (projétil do chefe)
img, d = canvas()
d.ellipse([4, 4, 11, 11], fill=(120, 220, 80, 255), outline=(40, 120, 30, 255))
d.point([(6, 6)], fill=(220, 255, 200, 255))
save(img, "veneno.png")
print("ok chama")
