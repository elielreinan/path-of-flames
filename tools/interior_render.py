"""Desenho dos interiores (piso, paredes, janelas, móveis) para o assador de cenário."""
import hashlib

import numpy as np
from PIL import Image, ImageDraw

import cenario_extra as extra

T = 16
OL = (23, 20, 36)

# Recortes do tileset Sunnyside (x, y, w, h) em pixels.
SPR = {
    "cama": (624, 536, 17, 24), "estante_livros": (672, 530, 16, 22), "estante_cores": (720, 530, 16, 22),
    "gaveteiro": (704, 530, 16, 22), "gaveteiro2": (688, 530, 16, 22), "armario": (736, 530, 13, 22),
    "comoda": (752, 536, 16, 16), "bacia": (768, 536, 13, 16), "mesa": (784, 539, 14, 13),
    "mesa_grande": (797, 574, 22, 27), "banquinho": (800, 538, 10, 14), "banco": (652, 611, 24, 13),
    "fogao": (666, 274, 16, 27), "barril": (626, 256, 14, 16), "barril_agua": (608, 256, 16, 16),
    "caixote": (600, 152, 16, 15), "caixotes": (624, 144, 32, 32), "vaso_girassol": (819, 512, 12, 15),
    "vaso_flor": (853, 512, 8, 16), "jarro": (754, 516, 10, 12), "jarro_azul": (739, 517, 10, 11),
    "espelho": (851, 546, 10, 12), "quadro": (867, 531, 11, 11), "quadro2": (852, 533, 9, 9),
    "balcao": (720, 197, 32, 11), "poco": (598, 311, 20, 25), "tapete_redondo": (751, 575, 18, 18),
}

# Paleta por cidade: papel de parede (claro, escuro), piso (claro, base, junta), rodapé.
TEMAS = {
    "areia_rubra": ((232, 176, 120), (212, 150, 100), (206, 146, 100), (186, 124, 86), (140, 88, 64), (150, 90, 62)),
    "oasis_miraj": ((132, 196, 168), (106, 172, 146), (214, 172, 120), (194, 150, 102), (150, 108, 76), (96, 120, 100)),
    "porto_coral": ((196, 222, 236), (164, 198, 220), (190, 170, 150), (166, 146, 128), (122, 104, 94), (92, 112, 140)),
    "vila_pescadores": ((206, 220, 214), (176, 198, 192), (186, 160, 128), (162, 136, 108), (118, 96, 80), (100, 120, 120)),
    "vale_ventos": ((170, 186, 140), (144, 164, 118), (176, 120, 84), (152, 98, 70), (108, 68, 52), (110, 80, 60)),
    "ruinas_qadim": ((222, 200, 150), (200, 176, 128), (196, 180, 150), (176, 160, 130), (136, 120, 98), (150, 120, 90)),
    "cidadela_sal": ((236, 236, 240), (212, 214, 224), (210, 200, 190), (190, 180, 170), (150, 140, 136), (140, 140, 156)),
    "aldeia_tamareiras": ((220, 196, 120), (198, 170, 98), (204, 156, 100), (182, 134, 84), (136, 94, 64), (140, 100, 60)),
    "padrao": ((214, 180, 140), (192, 156, 118), (202, 140, 96), (180, 120, 82), (130, 82, 60), (130, 84, 60)),
}
TAPETES = [((176, 52, 60), (226, 176, 70), (142, 36, 50)), ((52, 92, 170), (226, 196, 110), (36, 66, 130)),
           ((60, 132, 90), (230, 200, 120), (40, 100, 70)), ((150, 80, 150), (236, 200, 120), (110, 56, 116))]


def _h(*a):
    return int(hashlib.md5(":".join(map(str, a)).encode()).hexdigest()[:8], 16)


class Interior:
    def __init__(self, tileset_rgba):
        self.ts = tileset_rgba
        self.cache = {}

    def spr(self, nome):
        if nome not in self.cache:
            x, y, w, h = SPR[nome]
            self.cache[nome] = self.ts.crop((x, y, x + w, y + h))
        return self.cache[nome]

    def tema(self, data, map_id):
        t = data.get("tema")
        if not t:
            t = next((k for k in TEMAS if k in map_id), "padrao")
            if map_id == "casa_mae":
                t = "areia_rubra"
            elif map_id == "palacio_miraj":
                t = "oasis_miraj"
        return TEMAS.get(t, TEMAS["padrao"])

    # -------------------------------------------------------------- piso
    def piso(self, img, x, y, tema, map_id):
        d = ImageDraw.Draw(img)
        claro, base, junta = tema[2], tema[3], tema[4]
        px, py = x * T, y * T
        d.rectangle([px, py, px + T - 1, py + T - 1], fill=base)
        # Tábuas horizontais de 4 px com emendas desencontradas.
        for i in range(4):
            yy = py + i * 4
            d.line([(px, yy), (px + T - 1, yy)], fill=junta)
            d.line([(px, yy + 1), (px + T - 1, yy + 1)], fill=claro)
            off = (_h(map_id, x, y, i) % 3) * 5 + (i % 2) * 8
            sx = px + off % T
            d.line([(sx, yy), (sx, yy + 3)], fill=junta)
        if _h(map_id, x, y, "n") % 7 == 0:
            d.point([(px + 3 + _h(x, y) % 9, py + 2 + _h(y, x) % 12)], fill=junta)

    # -------------------------------------------------------------- paredes
    def parede(self, img, g, x, y, tema):
        h, w = len(g), len(g[0])
        d = ImageDraw.Draw(img)
        px, py = x * T, y * T
        abaixo = g[y + 1][x] if y + 1 < h else "w"
        if abaixo not in "wD":
            # Face da parede: papel listrado, moldura em cima, rodapé embaixo.
            d.rectangle([px, py, px + T - 1, py + T - 1], fill=tema[0])
            for xx in range(px + (x % 2) * 4, px + T, 8):
                d.rectangle([xx, py + 3, xx + 1, py + T - 5], fill=tema[1])
            d.rectangle([px, py, px + T - 1, py + 2], fill=(118, 72, 56))
            d.line([(px, py + 2), (px + T - 1, py + 2)], fill=(86, 52, 44))
            d.rectangle([px, py + T - 4, px + T - 1, py + T - 1], fill=tema[5])
            d.line([(px, py + T - 4), (px + T - 1, py + T - 4)], fill=tuple(min(255, c + 30) for c in tema[5]))
            d.line([(px, py + T - 1), (px + T - 1, py + T - 1)], fill=OL)
            if y > 0 and g[y - 1][x] not in "wD":
                # Divisória no meio da casa: topo da parede visível em cima da face.
                d.rectangle([px, py, px + T - 1, py + 6], fill=(86, 54, 46))
                d.rectangle([px, py, px + T - 1, py + 2], fill=(104, 66, 54))
                d.line([(px, py + 6), (px + T - 1, py + 6)], fill=OL)
        else:
            # Topo da parede (visto de cima): viga escura.
            d.rectangle([px, py, px + T - 1, py + T - 1], fill=(86, 54, 46))
            d.rectangle([px, py, px + T - 1, py + 3], fill=(104, 66, 54))
            for xx in range(px + 2, px + T, 6):
                d.point([(xx, py + 9)], fill=(70, 42, 38))
        # Contorno onde a parede encontra o chão dos lados.
        for dx, x0, x1 in ((-1, px, px), (1, px + T - 1, px + T - 1)):
            nx = x + dx
            if 0 <= nx < w and g[y][nx] not in "wD":
                d.line([(x0, py), (x1, py + T - 1)], fill=OL)
        if y > 0 and g[y - 1][x] not in "wD":
            d.line([(px, py), (px + T - 1, py)], fill=OL)

    def porta(self, img, x, y, tema, map_id):
        self.piso(img, x, y, tema, map_id)
        d = ImageDraw.Draw(img)
        px, py = x * T, y * T
        d.rectangle([px + 2, py + 2, px + 13, py + 13], fill=(150, 70, 60), outline=OL)
        for yy in range(py + 4, py + 12, 2):
            d.line([(px + 4, yy), (px + 11, yy)], fill=(176, 92, 72))
        d.rectangle([px - 1, py, px, py + T - 1], fill=(86, 54, 46))
        d.rectangle([px + T - 1, py, px + T, py + T - 1], fill=(86, 54, 46))

    # -------------------------------------------------------------- decoração de parede
    def janela(self, img, x, y):
        d = ImageDraw.Draw(img)
        px, py = x * T, y * T
        d.rectangle([px + 2, py + 3, px + 13, py + 12], fill=(132, 86, 58), outline=OL)
        d.rectangle([px + 4, py + 5, px + 11, py + 10], fill=(150, 214, 240))
        d.line([(px + 4, py + 5), (px + 7, py + 5)], fill=(220, 246, 255))
        d.line([(px + 7, py + 5), (px + 7, py + 10)], fill=(132, 86, 58))
        d.line([(px + 4, py + 8), (px + 11, py + 8)], fill=(132, 86, 58))
        d.rectangle([px + 1, py + 12, px + 14, py + 13], fill=(160, 108, 74), outline=OL)

    def luz_janela(self, img, x, y):
        luz = Image.new("RGBA", img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(luz)
        px, py = x * T, (y + 1) * T
        d.polygon([(px + 3, py), (px + 13, py), (px + 17, py + 22), (px + 7, py + 22)], fill=(255, 244, 200, 46))
        img.alpha_composite(luz)

    def rede(self, img, x, y):
        d = ImageDraw.Draw(img)
        px, py = x * T, y * T
        for i in range(0, 14, 3):
            d.line([(px + 1 + i, py + 3), (px + 1 + i // 2 + 4, py + 13)], fill=(150, 120, 80))
        for j in range(4, 13, 3):
            d.line([(px + 1, py + j), (px + 14, py + j)], fill=(150, 120, 80))
        d.line([(px, py + 3), (px + 15, py + 3)], fill=(110, 80, 56))
        d.ellipse([px + 10, py + 9, px + 13, py + 12], fill=(220, 80, 60), outline=OL)

    # -------------------------------------------------------------- tapete do tamanho da área
    def tapete(self, img, area, var):
        x, y, w, h = area
        cor, borda, esc = TAPETES[var % len(TAPETES)]
        d = ImageDraw.Draw(img)
        x0, y0, x1, y1 = x * T + 2, y * T + 2, (x + w) * T - 3, (y + h) * T - 3
        d.rectangle([x0, y0, x1, y1], fill=cor, outline=OL)
        d.rectangle([x0 + 2, y0 + 2, x1 - 2, y1 - 2], outline=borda)
        for xx in range(x0 + 5, x1 - 3, 6):
            for yy in range(y0 + 5, y1 - 3, 6):
                d.point([(xx, yy), (xx + 1, yy), (xx, yy + 1)], fill=esc)
                d.point([(xx + 1, yy + 1)], fill=borda)
        for xx in range(x0, x1 + 1, 3):
            d.point([(xx, y0 - 1), (xx, y1 + 1)], fill=borda)

    def balcao(self, img, area):
        x, y, w, h = area
        d = ImageDraw.Draw(img)
        x0, y0, x1, y1 = x * T, y * T + 2, (x + w) * T - 1, (y + h) * T - 1
        d.rectangle([x0, y0 + 4, x1, y1], fill=(150, 96, 66), outline=OL)
        d.rectangle([x0, y0, x1, y0 + 5], fill=(202, 140, 96), outline=OL)
        for xx in range(x0 + 3, x1 - 2, 4):
            d.line([(xx, y0 + 7), (xx, y1 - 2)], fill=(126, 78, 56))
        for i, xx in enumerate(range(x0 + 3, x1 - 4, 7)):
            c = [(230, 120, 60), (120, 190, 90), (240, 210, 90), (200, 80, 80)][i % 4]
            d.ellipse([xx, y0 - 2, xx + 4, y0 + 2], fill=c, outline=OL)

    def sombra(self, img, cx_, by, larg):
        sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse([cx_ - larg // 2, by - 4, cx_ + larg // 2, by], fill=(30, 16, 30, 60))
        img.alpha_composite(sh)

    def movel(self, img, nome, area, ocup):
        x, y, w, h = area
        if nome == "balcao":
            return self.balcao(img, area)
        if nome == "estante_livros":
            # Estante contínua do tamanho do bloco, um pouco mais alta que o tile (encosta na parede).
            s = extra.estante(w * T, _h(x, y, w), alt=h * T + 8)
            self.sombra(img, x * T + w * T // 2, (y + h) * T, w * T)
            img.alpha_composite(s, (x * T, (y + h) * T - s.height))
            return
        if nome == "trono":
            s = extra.trono()
            self.sombra(img, x * T + w * T // 2, (y + h) * T, s.width)
            img.alpha_composite(s, (x * T + (w * T - s.width) // 2, (y + h) * T - s.height + 1))
            return
        if nome in ("tapete", "tapete_grande") or nome not in SPR:
            return
        s = self.spr(nome)
        # Sombra.
        sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(sh)
        cx = x * T + w * T // 2
        by = (y + h) * T
        d.ellipse([cx - s.width // 2, by - 4, cx + s.width // 2, by], fill=(30, 16, 30, 60))
        img.alpha_composite(sh)
        img.alpha_composite(s, (cx - s.width // 2, by - s.height - (0 if h > 1 or s.height > T else 1)))

    def desenhar(self, data, map_id, g, img):
        h, w = len(g), len(g[0])
        tema = self.tema(data, map_id)
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if ch == "w":
                    self.parede(img, g, x, y, tema)
                elif ch == "D":
                    self.porta(img, x, y, tema, map_id)
                elif ch in "fmPEbKh":
                    self.piso(img, x, y, tema, map_id)
        # Biblioteca: as paredes de trás viram estantes embutidas.
        if "biblioteca" in map_id:
            for y in range(h - 1):
                x = 0
                while x < w:
                    face = lambda xx: g[y][xx] == "w" and g[y + 1][xx] not in "wD" and (y == 0 or g[y - 1][xx] in "wD")
                    if face(x):
                        x1 = x
                        while x1 + 1 < w and face(x1 + 1):
                            x1 += 1
                        s = extra.estante((x1 - x + 1) * T, _h(map_id, x, y), alt=T - 1, cheia=0.9)
                        img.alpha_composite(s, (x * T, y * T))
                        x = x1 + 1
                    else:
                        x += 1
        # Carpete 'P' do layout: vira tapete contínuo.
        vis = set()
        for y in range(h):
            for x in range(w):
                if g[y][x] == "P" and (x, y) not in vis:
                    x1 = x
                    while x1 + 1 < w and g[y][x1 + 1] == "P":
                        x1 += 1
                    y1 = y
                    while y1 + 1 < h and all(g[y1 + 1][xx] == "P" for xx in range(x, x1 + 1)):
                        y1 += 1
                    for yy in range(y, y1 + 1):
                        for xx in range(x, x1 + 1):
                            vis.add((xx, yy))
                    area = [x, y, x1 - x + 1, y1 - y + 1]
                    self.tapete(img, area, 0 if area[2] * area[3] > 30 else _h(map_id, x, y))
        deco = list(data.get("decoracao", []))
        cobertos = set()
        for dd in deco:
            x, y, ww, hh = dd["area"]
            for yy in range(y, y + hh):
                for xx in range(x, x + ww):
                    cobertos.add((xx, yy))
        # Objetos antigos do layout sem decoração: viram móveis do Sunnyside.
        antigos = {"E": "estante_livros", "m": "mesa", "K": "caixote", "h": "poco"}
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if (x, y) in cobertos:
                    continue
                if ch == "b":
                    if y > 0 and g[y - 1][x] == "b" and (x, y - 1) not in cobertos:
                        continue
                    alto = 2 if y + 1 < h and g[y + 1][x] == "b" else 1
                    deco.append({"s": "cama", "area": [x, y, 1, alto]})
                elif ch == "E":
                    # Fileira de 'E' vira uma estante comprida só.
                    if x > 0 and g[y][x - 1] == "E" and (x - 1, y) not in cobertos:
                        continue
                    x1 = x
                    while x1 + 1 < w and g[y][x1 + 1] == "E":
                        x1 += 1
                    deco.append({"s": "estante_livros", "area": [x, y, x1 - x + 1, 1]})
                elif ch in antigos:
                    deco.append({"s": antigos[ch], "area": [x, y, 1, 1]})
        # Luz das janelas no chão, depois tapetes, depois móveis de trás para frente.
        for dd in deco:
            if dd.get("parede") and dd["s"] == "janela":
                self.luz_janela(img, dd["area"][0], dd["area"][1])
        for i, dd in enumerate(deco):
            if dd["s"] in ("tapete", "tapete_grande"):
                self.tapete(img, dd["area"], _h(map_id, i))
            elif dd["s"] == "tapete_redondo":
                self.movel(img, dd["s"], dd["area"], None)
        for dd in deco:
            if dd.get("parede"):
                x, y = dd["area"][:2]
                if dd["s"] == "janela":
                    self.janela(img, x, y)
                elif dd["s"] == "rede":
                    self.rede(img, x, y)
                elif dd["s"] in SPR:
                    s = self.spr(dd["s"])
                    img.alpha_composite(s, (x * T + (T - s.width) // 2, y * T + (T - s.height) // 2))
        for dd in sorted((d for d in deco if not d.get("parede") and d["s"] not in ("tapete", "tapete_grande", "tapete_redondo")),
                         key=lambda d: d["area"][1] + d["area"][3]):
            self.movel(img, dd["s"], dd["area"], None)
        return img
