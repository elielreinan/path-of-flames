"""Sprites das criaturas e chefes dos capítulos 2 a 7.
Uso: python3 tools/gerar_criaturas.py  (rodar na pasta game/)"""
from PIL import Image, ImageDraw
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets")

def canvas(s=16):
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)

def save(img, name):
    img.save(os.path.join(OUT, name))

# Hiena
img, d = canvas()
d.ellipse([3, 6, 13, 12], fill=(170, 140, 90, 255))
d.ellipse([10, 3, 15, 9], fill=(170, 140, 90, 255))
d.polygon([(11, 3), (12, 0), (13, 3)], fill=(120, 95, 60, 255))
for x in (4, 6, 10, 12):
    d.line([(x, 12), (x, 15)], fill=(120, 95, 60, 255))
for x, y in ((5, 7), (8, 8), (6, 10)):
    d.point((x, y), fill=(90, 60, 40, 255))
d.point((13, 5), fill=(20, 20, 20, 255))
d.line([(2, 7), (0, 5)], fill=(120, 95, 60, 255))
save(img, "hiena.png")

# Sapo venenoso
img, d = canvas()
d.ellipse([2, 6, 14, 15], fill=(80, 170, 200, 255), outline=(30, 80, 110, 255))
d.ellipse([3, 3, 7, 8], fill=(80, 170, 200, 255))
d.ellipse([9, 3, 13, 8], fill=(80, 170, 200, 255))
d.point([(5, 5), (11, 5)], fill=(20, 20, 20, 255))
for x, y in ((6, 10), (10, 11), (8, 13)):
    d.point((x, y), fill=(240, 220, 60, 255))
save(img, "sapo.png")

# Serpente do Oásis (chefe 32x32)
img, d = canvas(32)
d.line([(3, 28), (8, 22), (14, 26), (20, 20), (22, 14)], fill=(40, 120, 110, 255), width=6)
d.line([(3, 28), (8, 22), (14, 26), (20, 20), (22, 14)], fill=(220, 200, 80, 255), width=1)
d.ellipse([16, 3, 30, 15], fill=(50, 140, 130, 255), outline=(20, 70, 60, 255))
d.polygon([(18, 4), (16, 0), (21, 3)], fill=(220, 60, 60, 255))
d.polygon([(28, 4), (30, 0), (25, 3)], fill=(220, 60, 60, 255))
d.point([(20, 8), (21, 8), (25, 8), (26, 8)], fill=(255, 220, 40, 255))
d.line([(23, 15), (23, 18)], fill=(220, 40, 60, 255))
save(img, "serpente_oasis.png")

# Caranguejo
img, d = canvas()
d.ellipse([3, 6, 13, 13], fill=(220, 90, 60, 255), outline=(130, 40, 30, 255))
d.ellipse([0, 3, 4, 7], fill=(230, 100, 70, 255))
d.ellipse([12, 3, 16, 7], fill=(230, 100, 70, 255))
d.point([(6, 6), (10, 6)], fill=(20, 20, 20, 255))
for x in (3, 5, 11, 13):
    d.line([(x, 12), (x - 1 if x < 8 else x + 1, 15)], fill=(130, 40, 30, 255))
save(img, "caranguejo.png")

# Lobo de metal
img, d = canvas()
d.rectangle([3, 6, 12, 11], fill=(140, 150, 160, 255), outline=(70, 75, 85, 255))
d.polygon([(11, 3), (16, 6), (11, 9)], fill=(150, 160, 170, 255), outline=(70, 75, 85, 255))
d.polygon([(11, 3), (12, 0), (13, 4)], fill=(100, 110, 120, 255))
d.point((13, 5), fill=(255, 60, 40, 255))
for x in (4, 6, 9, 11):
    d.line([(x, 11), (x, 15)], fill=(70, 75, 85, 255))
d.line([(3, 7), (0, 4)], fill=(100, 110, 120, 255))
d.point([(6, 8), (8, 8)], fill=(220, 170, 60, 255))
save(img, "lobo_metal.png")

# Águia
img, d = canvas()
d.polygon([(8, 7), (0, 2), (1, 9)], fill=(110, 70, 40, 255))
d.polygon([(8, 7), (16, 2), (15, 9)], fill=(110, 70, 40, 255))
d.ellipse([5, 5, 11, 13], fill=(130, 85, 50, 255))
d.ellipse([6, 2, 10, 7], fill=(240, 240, 230, 255))
d.point([(7, 4)], fill=(20, 20, 20, 255))
d.polygon([(9, 5), (11, 5), (9, 6)], fill=(240, 190, 40, 255))
save(img, "aguia.png")

# Grifo de Ferro (chefe 32x32)
img, d = canvas(32)
d.polygon([(16, 14), (0, 4), (4, 20)], fill=(120, 125, 135, 255), outline=(60, 62, 70, 255))
d.polygon([(16, 14), (32, 4), (28, 20)], fill=(120, 125, 135, 255), outline=(60, 62, 70, 255))
d.ellipse([9, 10, 23, 26], fill=(150, 155, 165, 255), outline=(60, 62, 70, 255))
d.ellipse([11, 3, 21, 13], fill=(170, 175, 185, 255), outline=(60, 62, 70, 255))
d.polygon([(19, 8), (25, 9), (19, 11)], fill=(230, 180, 50, 255))
d.point([(14, 7), (17, 7)], fill=(255, 60, 40, 255))
for x in (12, 19):
    d.line([(x, 25), (x, 31)], fill=(60, 62, 70, 255), width=2)
d.ellipse([14, 16, 18, 20], fill=(230, 180, 50, 255))
save(img, "grifo_ferro.png")

# Golem de Vidro (chefe 32x32)
img, d = canvas(32)
glass = (140, 220, 230, 210)
edge = (60, 140, 160, 255)
d.rectangle([8, 9, 23, 23], fill=glass, outline=edge)
d.rectangle([11, 1, 20, 9], fill=glass, outline=edge)
d.rectangle([2, 10, 7, 21], fill=glass, outline=edge)
d.rectangle([24, 10, 29, 21], fill=glass, outline=edge)
d.rectangle([9, 23, 14, 31], fill=glass, outline=edge)
d.rectangle([17, 23, 22, 31], fill=glass, outline=edge)
d.rectangle([13, 4, 14, 5], fill=(255, 120, 40, 255))
d.rectangle([17, 4, 18, 5], fill=(255, 120, 40, 255))
d.line([(10, 12), (15, 18)], fill=(230, 255, 255, 255))
d.ellipse([14, 13, 18, 17], fill=(255, 140, 40, 255))
save(img, "golem_vidro.png")

# Sombra
img, d = canvas()
d.polygon([(8, 1), (14, 8), (13, 15), (10, 12), (8, 15), (6, 12), (3, 15), (2, 8)], fill=(50, 30, 70, 220))
d.point([(6, 6), (10, 6)], fill=(230, 60, 220, 255))
save(img, "sombra.png")

# Livro (item)
img, d = canvas()
d.rectangle([3, 3, 12, 13], fill=(130, 40, 40, 255), outline=(70, 20, 20, 255))
d.rectangle([5, 5, 10, 7], fill=(230, 190, 70, 255))
d.line([(12, 4), (12, 13)], fill=(240, 230, 210, 255))
save(img, "livro.png")

# Peixe (item)
img, d = canvas()
d.ellipse([3, 6, 12, 11], fill=(120, 170, 210, 255))
d.polygon([(11, 8), (15, 5), (15, 12)], fill=(100, 150, 190, 255))
d.point((5, 8), fill=(20, 20, 20, 255))
save(img, "peixe.png")

# Flor de lótus (item)
img, d = canvas()
d.ellipse([2, 10, 14, 14], fill=(70, 150, 80, 255))
d.polygon([(8, 3), (10, 9), (8, 11), (6, 9)], fill=(250, 170, 200, 255))
d.polygon([(4, 6), (8, 10), (5, 11)], fill=(240, 140, 180, 255))
d.polygon([(12, 6), (8, 10), (11, 11)], fill=(240, 140, 180, 255))
save(img, "lotus.png")

# Engrenagem (item)
img, d = canvas()
d.ellipse([3, 3, 12, 12], fill=(150, 150, 160, 255), outline=(80, 80, 90, 255))
for x, y in ((7, 1), (7, 12), (1, 7), (12, 7)):
    d.rectangle([x, y, x + 2, y + 2], fill=(150, 150, 160, 255))
d.ellipse([6, 6, 9, 9], fill=(60, 60, 70, 255))
save(img, "engrenagem.png")

# Sino (item)
img, d = canvas()
d.polygon([(8, 2), (12, 11), (4, 11)], fill=(230, 190, 70, 255), outline=(150, 110, 30, 255))
d.ellipse([7, 11, 9, 13], fill=(150, 110, 30, 255))
save(img, "sino.png")

# Chamas sagradas coloridas de cada cidade reaproveitam chama_sagrada.png com cor no JSON.
print("ok criaturas")

# Ovelha
img, d = canvas()
d.ellipse([2, 5, 13, 13], fill=(240, 240, 235, 255), outline=(180, 180, 175, 255))
d.ellipse([10, 4, 15, 9], fill=(60, 50, 50, 255))
d.point((13, 6), fill=(255, 255, 255, 255))
for x in (4, 10):
    d.line([(x, 13), (x, 15)], fill=(60, 50, 50, 255))
save(img, "ovelha.png")

# Estátua
img, d = canvas(16)
d.rectangle([3, 12, 12, 15], fill=(130, 125, 120, 255), outline=(80, 75, 70, 255))
d.rectangle([5, 4, 10, 12], fill=(170, 165, 155, 255), outline=(90, 85, 80, 255))
d.ellipse([5, 0, 10, 5], fill=(170, 165, 155, 255), outline=(90, 85, 80, 255))
save(img, "estatua.png")

# Fantasma
img, d = canvas()
d.polygon([(3, 15), (3, 6), (8, 1), (13, 6), (13, 15), (11, 13), (8, 15), (5, 13)], fill=(200, 230, 255, 170))
d.point([(6, 6), (10, 6)], fill=(40, 60, 120, 255))
save(img, "fantasma.png")
print("ok extra criaturas")

# ---------- Montarias (24x20, olhando para a direita, com sela) ----------
SELA = (150, 40, 30, 255)
SELA_BORDA = (240, 190, 60, 255)

def sela(d, x, y, w=7):
    d.rectangle([x, y, x + w, y + 2], fill=SELA)
    d.line([(x, y + 2), (x + w, y + 2)], fill=SELA_BORDA)
    d.line([(x + 2, y + 3), (x + 2, y + 5)], fill=(90, 60, 40, 255))

# Camelo
img, d = canvas(24)
pelo, sombra = (205, 160, 95, 255), (150, 110, 60, 255)
d.ellipse([3, 7, 17, 15], fill=pelo)                     # corpo
d.ellipse([6, 4, 12, 10], fill=pelo)                      # corcova
d.polygon([(16, 9), (19, 3), (21, 3), (19, 10)], fill=pelo)  # pescoço
d.ellipse([18, 1, 23, 5], fill=pelo)                      # cabeça
d.point((21, 2), fill=(30, 20, 10, 255))
d.point((23, 4), fill=sombra)
for x in (5, 8, 13, 16):
    d.line([(x, 14), (x, 19)], fill=sombra, width=1)
    d.point((x, 19), fill=(80, 60, 40, 255))
d.line([(3, 9), (1, 12)], fill=sombra)
sela(d, 6, 6, 6)
save(img, "montaria_camelo.png")

# Hiena domada
img, d = canvas(24)
pelo, sombra = (175, 145, 95, 255), (120, 95, 60, 255)
d.ellipse([3, 8, 17, 15], fill=pelo)
d.ellipse([15, 4, 22, 11], fill=pelo)
d.polygon([(16, 4), (17, 0), (19, 4)], fill=sombra)
d.point((20, 6), fill=(20, 20, 20, 255))
d.point((22, 9), fill=(40, 30, 20, 255))
for x, y in ((6, 10), (10, 11), (13, 9), (8, 13)):
    d.point((x, y), fill=(90, 60, 40, 255))
for x in (5, 8, 13, 16):
    d.line([(x, 14), (x, 19)], fill=sombra)
d.line([(3, 10), (0, 7)], fill=sombra)
sela(d, 6, 7, 7)
save(img, "montaria_hiena.png")

# Lobo de metal domado
img, d = canvas(24)
metal, sombra, olho = (150, 160, 175, 255), (90, 95, 110, 255), (90, 220, 255, 255)
d.rectangle([4, 8, 17, 14], fill=metal, outline=sombra)
d.polygon([(16, 9), (19, 3), (23, 6), (22, 10), (17, 12)], fill=metal, outline=sombra)
d.polygon([(18, 4), (18, 0), (20, 3)], fill=sombra)
d.point((21, 6), fill=olho)
for x in (5, 8, 13, 16):
    d.line([(x, 14), (x, 19)], fill=sombra)
d.line([(4, 9), (0, 6)], fill=sombra)
d.point([(7, 11), (10, 11), (13, 11)], fill=(200, 120, 40, 255))
sela(d, 6, 6, 7)
save(img, "montaria_lobo.png")
print("montarias geradas")

# Boneco de treino (palha e madeira)
img, d = canvas()
d.line([(8, 6), (8, 15)], fill=(110, 75, 40, 255), width=2)
d.line([(3, 8), (13, 8)], fill=(110, 75, 40, 255), width=2)
d.ellipse([4, 6, 12, 13], fill=(215, 180, 90, 255), outline=(150, 115, 50, 255))
d.ellipse([5, 0, 11, 6], fill=(225, 190, 100, 255), outline=(150, 115, 50, 255))
d.line([(4, 10), (12, 10)], fill=(170, 60, 40, 255))
d.point([(7, 3), (9, 3)], fill=(60, 40, 20, 255))
d.ellipse([7, 8, 9, 10], outline=(200, 40, 30, 255))
save(img, "boneco.png")
print("boneco gerado")
