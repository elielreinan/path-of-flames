"""Assa o visual de cada mapa numa imagem (chão orgânico estilo Stardew/Sunnyside).
Uso (na pasta game/): python3 tools/assar_cenario.py data/mapas assets/cenario assets/cenario/mapas [mapa ...] [--tileset arquivo]
  <pasta assets/cenario>: tiles_sunny.png e objetos_sunny.png (estruturas e objetos).
A colisão continua vindo do layout (tile a tile); a imagem só muda o desenho:
bordas arredondadas e onduladas, praia em degradê, água com profundidade, paredões com face de pedra.
Árvores ('T') não entram na imagem: o jogo desenha como sprites com y-sort.
"""
import hashlib, json, os, sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from interior_render import Interior

T = 16
TILE_CHARS = ".,:fc#HRTWrmbDXCS JPKwghE=*"
OBJETOS = "TrmbCSKhE*"
CHAO = ".,:fcP"
PENHASCO = {"desfiladeiro_sal", "trilha_penhascos"}
# Fortalezas: '#' é bloco de alvenaria (topo de pedra + face de tijolo) e ':' é piso de lajotas.
FORTALEZA = {"fabrica_grifo", "quartel_varek"}
OL = (23, 20, 36)

# Classes de chão "macias" (se misturam com borda orgânica).
AREIA, GRAMA, CAMINHO, CAVERNA, AGUA, ROCHA, VAZIO, MADEIRA, TAPETE, MURO, LAJOTA = range(11)
MACIAS = [AREIA, GRAMA, CAMINHO, CAVERNA, AGUA, ROCHA, VAZIO]


def seed_of(*a):
    return int(hashlib.md5(":".join(map(str, a)).encode()).hexdigest()[:8], 16)


def noise(h, w, seed, period, octaves=3):
    rnd = np.random.default_rng(seed)
    out = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for _ in range(octaves):
        gh, gw = int(h / period) + 3, int(w / period) + 3
        lat = rnd.uniform(-1, 1, (gh, gw))
        ys, xs = np.arange(h) / period, np.arange(w) / period
        y0, x0 = ys.astype(int), xs.astype(int)
        fy, fx = (ys - y0)[:, None], (xs - x0)[None, :]
        fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
        a, b = lat[y0][:, x0], lat[y0][:, x0 + 1]
        c, d = lat[y0 + 1][:, x0], lat[y0 + 1][:, x0 + 1]
        out += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy)
        tot += amp
        amp *= 0.5
        period = max(1.0, period / 2)
    out /= tot
    return out / max(out.std(), 1e-6)


def box(m, r):
    """Média numa janela (2r+1)² usando soma acumulada."""
    p = np.pad(m, r, mode="edge")
    c = p.cumsum(0).cumsum(1)
    c = np.pad(c, ((1, 0), (1, 0)))
    k = 2 * r + 1
    return (c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]) / (k * k)


def blur(m, r):
    for _ in range(3):
        m = box(m, r)
    return m


def dist(mask, maxd):
    """Distância (aprox. octogonal) de cada pixel até o pixel mais próximo de 'mask', limitada a maxd."""
    d = np.where(mask, 0, maxd).astype(np.int32)
    cur = mask.copy()
    for i in range(1, maxd):
        n = cur.copy()
        n[1:] |= cur[:-1]
        n[:-1] |= cur[1:]
        n[:, 1:] |= cur[:, :-1]
        n[:, :-1] |= cur[:, 1:]
        if i % 2 == 0:
            n[1:, 1:] |= cur[:-1, :-1]
            n[:-1, :-1] |= cur[1:, 1:]
            n[1:, :-1] |= cur[:-1, 1:]
            n[:-1, 1:] |= cur[1:, :-1]
        novo = n & ~cur
        d[novo] = i
        cur = n
        if cur.all():
            break
    return d


def warp(m, dx, dy):
    h, w = m.shape
    ys, xs = np.mgrid[0:h, 0:w]
    sx = np.clip(np.rint(xs + dx), 0, w - 1).astype(int)
    sy = np.clip(np.rint(ys + dy), 0, h - 1).astype(int)
    return m[sy, sx]


TILESET = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "arte", "base", "sunnyside_world", "Tileset",
                       "spr_tileset_sunnysideworld_16px.png")
# Texturas do Sunnyside (coluna, linha) com pesos: as lisas aparecem mais.
TEX = {
    "grama": [((1, 2), 3), ((2, 2), 3), ((3, 2), 3), ((6, 3), 0), ((4, 2), 1), ((5, 2), 1), ((1, 3), 1), ((2, 3), 6), ((1, 1), 8)],
    "areia": [((42, 7), 4), ((43, 7), 4), ((42, 8), 2), ((43, 8), 2)],
    "caminho": [((9, 7), 2), ((10, 7), 2), ((11, 7), 3), ((9, 8), 2), ((10, 8), 3)],
    "caverna": [((10, 32), 4), ((11, 32), 2), ((12, 32), 2)],
}


PEDRA = {
    "deserto": [(226, 168, 112), (200, 136, 88), (164, 102, 70), (122, 72, 56)],
    "cinza": [(196, 204, 220), (158, 168, 188), (120, 128, 152), (86, 92, 118)],
    "caverna": [(132, 112, 128), (106, 88, 106), (80, 64, 84), (58, 44, 62)],
}


def pedra(tema, var):
    """Pedra arredondada 16x16 no estilo Sunnyside: contorno escuro, 3 tons e brilho no alto à esquerda."""
    rnd = np.random.default_rng(var * 7919 + len(tema))
    c = PEDRA[tema]
    out = np.zeros((T, T, 4), np.uint8)
    w = 11 + var % 3
    hgt = 8 + (var // 3) % 3
    cx, base = 8, 14
    ys, xs = np.mgrid[0:T, 0:T]
    # Forma: elipse achatada com bordas irregulares.
    ex = (xs + 0.5 - cx) / (w / 2)
    ey = (ys + 0.5 - (base - hgt / 2)) / (hgt / 2)
    ang = np.arctan2(ey, ex)
    r = 1 + 0.12 * np.sin(ang * 3 + var) + 0.06 * np.sin(ang * 5 + 2 * var)
    dentro = ex * ex + ey * ey < r * r
    # Sombra no chão.
    sh = (((xs + 0.5 - cx) / (w / 2 + 1)) ** 2 + ((ys + 0.5 - (base + 0.5)) / 1.6) ** 2) < 1
    out[sh & ~dentro] = (40, 20, 50, 80)
    luz = (-(xs - cx) * 0.6 - (ys - (base - hgt)) * 1.0)
    cor = np.full((T, T), 2)
    cor[luz > -hgt * 0.35] = 1
    cor[luz > hgt * 0.25] = 0
    cor[ys >= base - 1] = 3
    for i in range(4):
        sel = dentro & (cor == i)
        out[sel, :3] = c[i]
        out[sel, 3] = 255
    # Rachadura e pontinhos.
    for _ in range(2):
        x0, y0 = rnd.integers(cx - w // 3, cx + w // 3), rnd.integers(base - hgt + 2, base - 1)
        if dentro[y0, x0]:
            out[y0, x0, :3] = c[3]
    # Contorno.
    borda = np.zeros_like(dentro)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        borda |= np.roll(dentro, (dy, dx), (0, 1)) & ~dentro
    out[borda] = (*OL, 255)
    return Image.fromarray(out, "RGBA")


class Assador:
    def __init__(self, cenario_dir, tileset=TILESET):
        self.interior = Interior(Image.open(tileset).convert("RGBA"))
        ts = np.array(Image.open(tileset).convert("RGB"), np.float32)
        self.tex = {}
        for nome, lista in TEX.items():
            tiles = [ts[r * T:(r + 1) * T, c * T:(c + 1) * T] for (c, r), wgt in lista if wgt > 0]
            pesos = np.array([wgt for _, wgt in lista if wgt > 0], float)
            self.tex[nome] = (np.stack(tiles), pesos / pesos.sum())
        self.atlas = Image.open(os.path.join(cenario_dir, "tiles_sunny.png")).convert("RGBA")
        self.obj = Image.open(os.path.join(cenario_dir, "objetos_sunny.png")).convert("RGBA")

    # ------------------------------------------------------------------ classes
    def classes(self, rows, map_id):
        h, w = len(rows), max(len(r) for r in rows)
        g = [list(r.ljust(w)) for r in rows]
        cls = np.full((h, w), AREIA, np.int32)
        estrut = np.zeros((h, w), bool)
        flat = "".join(rows)
        caverna = flat.count("c") > flat.count(".") + flat.count(",")

        def chao_viz(x, y):
            for r in range(1, 5):
                conta = {}
                for dy in range(-r, r + 1):
                    for dx in range(-r, r + 1):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < w and 0 <= yy < h and g[yy][xx] in CHAO:
                            conta[g[yy][xx]] = conta.get(g[yy][xx], 0) + (2 if dx == 0 or dy == 0 else 1)
                if conta:
                    return max(conta, key=conta.get)
            return "c" if caverna else "."
        m = {".": AREIA, ",": GRAMA, ":": CAMINHO, "c": CAVERNA, "W": AGUA, "X": ROCHA,
             " ": VAZIO, "f": MADEIRA, "P": TAPETE}
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if ch == "#" and map_id in PENHASCO:
                    cls[y, x] = ROCHA
                elif ch == "#" and map_id in FORTALEZA:
                    cls[y, x] = MURO
                elif ch == ":" and map_id in FORTALEZA:
                    cls[y, x] = LAJOTA
                elif ch in m:
                    cls[y, x] = m[ch]
                elif ch == "=":
                    cls[y, x] = AGUA if any(g[yy][xx] == "W" for yy in range(max(0, y - 2), min(h, y + 3))
                                            for xx in range(max(0, x - 2), min(w, x + 3))) else VAZIO
                    estrut[y, x] = True
                elif ch in OBJETOS:
                    cls[y, x] = m[chao_viz(x, y)]
                else:
                    cls[y, x] = m.get(chao_viz(x, y), AREIA)
                    estrut[y, x] = True
        return g, cls, estrut, caverna

    # ------------------------------------------------------------------ campo de pixels
    def campo(self, cls, map_id):
        h, w = cls.shape
        H, W = h * T, w * T
        up = np.repeat(np.repeat(cls, T, 0), T, 1)
        dx = noise(H, W, seed_of(map_id, "dx"), 22) * 2.6 + noise(H, W, seed_of(map_id, "dx2"), 6) * 0.9
        dy = noise(H, W, seed_of(map_id, "dy"), 22) * 2.6 + noise(H, W, seed_of(map_id, "dy2"), 6) * 0.9
        best = np.full((H, W), -9.0)
        out = np.zeros((H, W), np.int32)
        presentes = [c for c in MACIAS if (cls == c).any()]
        # Prioridade leve: caminho cede para grama, grama cede para água/rocha.
        bias = {AREIA: 0.0, GRAMA: 0.02, CAMINHO: -0.04, CAVERNA: 0.0, AGUA: 0.03, ROCHA: 0.03, VAZIO: 0.03}
        for c in presentes:
            f = blur((up == c).astype(float), 3)
            f = warp(f, dx, dy) + bias[c]
            sel = f > best
            best[sel] = f[sel]
            out[sel] = c
        duro = (up == MADEIRA) | (up == TAPETE) | (up == MURO) | (up == LAJOTA)
        out[duro] = up[duro]
        return out

    # ------------------------------------------------------------------ texturas
    def textura(self, nome, H, W, map_id):
        tiles, pesos = self.tex[nome]
        h, w = H // T, W // T
        rnd = np.random.default_rng(seed_of(map_id, nome))
        var = rnd.choice(len(tiles), size=(h, w), p=pesos)
        ys, xs = np.mgrid[0:H, 0:W]
        return tiles[var[ys // T, xs // T], ys % T, xs % T]

    def pintar(self, px, map_id, caverna, deserto):
        H, W = px.shape
        img = np.zeros((H, W, 3), np.float32)
        rnd = np.random.default_rng(seed_of(map_id, "tex"))
        n1 = noise(H, W, seed_of(map_id, "n1"), 10)
        n2 = noise(H, W, seed_of(map_id, "n2"), 3)
        fino = rnd.random((H, W))
        ys, xs = np.mgrid[0:H, 0:W]

        def pal(mask, cores, campo, cortes):
            """Pinta 'mask' escolhendo a cor pela faixa de 'campo' (pixel art: faixas, sem gradiente)."""
            idx = np.digitize(campo, cortes)
            for i, c in enumerate(cores):
                sel = mask & (idx == i)
                img[sel] = c

        agua = px == AGUA
        rocha = px == ROCHA
        vazio = px == VAZIO
        d_agua = dist(agua, 40)
        madeira = px == MADEIRA
        tapete = px == TAPETE
        d_terra = dist(~agua & ~vazio & ~madeira & ~tapete, 48)
        d_casco = dist(madeira, 4)
        d_rocha = dist(rocha, 12)

        areia = px == AREIA
        grama = px == GRAMA
        cam = px == CAMINHO
        cav = px == CAVERNA
        for nome, msk in (("areia", areia), ("grama", grama), ("caminho", cam), ("caverna", cav)):
            if msk.any():
                img[msk] = self.textura(nome, H, W, map_id)[msk]
        # Tom levemente variado em manchas grandes (quase imperceptível).
        tom = (1 + 0.015 * np.clip(n1, -2, 2))[..., None]
        img[areia | grama | cam] = (img * tom)[areia | grama | cam]
        # Areia molhada perto da água (faixas).
        wet = d_agua + (n2 * 1.4).astype(int)
        pal(areia & (wet < 12), [(176, 128, 82), (192, 144, 88), (206, 160, 96), (216, 176, 104)], wet, [2, 5, 8])
        # Barranco de terra úmida onde a grama ou o caminho encostam na água.
        bank = (grama | cam) & (wet < 5)
        pal(bank, [(132, 88, 66), (156, 106, 76), (176, 124, 84)], wet, [2, 4])
        # Caverna mais escura perto das paredes.
        for lim, f in ((5, 0.86), (3, 0.82), (1, 0.85)):
            sel = cav & (d_rocha < lim)
            img[sel] *= f
        # Água: espuma, raso, médio e fundo, com faixas onduladas.
        prof = d_terra + (n2 * 1.8 + n1 * 1.5).astype(int)
        grande = agua.sum() > 200 * T * T
        cortes = [2, 5, 10, 18, 30] if grande else [2, 5, 9, 15, 24]
        pal(agua, [(232, 246, 250), (120, 222, 236), (60, 200, 232), (17, 163, 227), (0, 140, 210), (24, 104, 196)],
            prof, cortes)
        # Ondinhas: tracinhos claros espalhados na água funda.
        onda = agua & (prof > 12) & (noise(H, W, seed_of(map_id, "onda"), 3) > 1.9) & (fino > 0.5)
        img[onda] = np.minimum(img[onda] + 40, 255)
        brilho = agua & (prof > 8) & (fino > 0.996)
        for k in range(3):
            img[np.roll(brilho, k, 1) & agua] = (170, 236, 250)
        # Espuma em volta do casco de navios e píeres de madeira.
        espuma = d_casco + (n2 * 0.8).astype(int)
        img[agua & (espuma <= 2)] = (232, 246, 250)
        img[agua & (espuma == 3) & (fino > 0.35)] = (150, 226, 240)
        # Convés / piso de madeira: tábuas horizontais.
        if madeira.any():
            tab = (ys // 4) % 2
            emenda = ((xs + (ys // 4) * 7) % 24) == 0
            img[madeira] = (186, 128, 84)
            img[madeira & (tab == 1)] = (172, 116, 76)
            img[madeira & (ys % 4 == 0)] = (120, 76, 56)
            img[madeira & emenda] = (120, 76, 56)
            img[madeira & (ys % 4 == 1)] = (206, 150, 104)
        # Tapete/carpete: vermelho com barra dourada nas bordas da região.
        if tapete.any():
            dt = dist(~tapete, 6)
            img[tapete] = (150, 40, 52)
            img[tapete & ((xs // 4 + ys // 4) % 2 == 0) & (dt > 4)] = (166, 50, 60)
            img[tapete & (dt <= 3)] = (214, 168, 70)
            img[tapete & (dt == 2)] = (176, 120, 50)
            img[tapete & (dt <= 1)] = OL
        # Lajotas (fortalezas).
        laj = px == LAJOTA
        if laj.any():
            img[laj] = (150, 156, 170)
            img[laj & ((xs % 16 == 0) | (ys % 8 == 0) | (((xs + (ys // 8) * 8) % 16 == 8) & (ys % 8 != 0)))] = (112, 116, 134)
            img[laj & (fino > 0.97)] = (132, 138, 152)
            img[laj & ((ys % 8) == 1) & (xs % 16 != 0)] = (170, 176, 190)
        # Alvenaria: topo de pedra escura e face de tijolos virada para o sul.
        muro = px == MURO
        if muro.any():
            sh = muro.copy()
            face = np.zeros_like(muro)
            for k in range(1, 15):
                sh = np.roll(sh, -1, 0)
                sh[-1] = True
                face |= muro & ~sh
            topo = muro & ~face
            img[topo] = (70, 72, 92)
            img[topo & ((xs + ys) % 6 == 0)] = (78, 80, 100)
            img[topo & (fino > 0.98)] = (58, 60, 78)
            tij = face & ((ys % 5 == 0) | (((xs + (ys // 5) * 4) % 8) == 0))
            img[face] = (150, 104, 92)
            img[tij] = (110, 74, 70)
            img[face & (ys % 5 == 1) & ~tij] = (172, 124, 108)
            bm = muro & ~(np.roll(muro, 1, 0) & np.roll(muro, -1, 0) & np.roll(muro, 1, 1) & np.roll(muro, -1, 1))
            img[bm] = OL
            img[~muro & (np.roll(muro, 1, 0) | np.roll(muro, 2, 0))] *= 0.7
        # Vazio (abismo de cinzas).
        cinza = vazio
        pal(cinza, [(12, 7, 16), (17, 10, 21), (24, 13, 26)], n1, [-0.8, 0.9])
        img[cinza & (fino > 0.9985)] = (200, 90, 50)
        img[cinza & (fino > 0.9996)] = (255, 190, 90)

        # Rocha: topo e face (paredão voltado para o sul).
        if rocha.any():
            # Altura da face: quantos pixels abaixo até sair da rocha.
            face_h = 13
            abaixo = np.zeros_like(rocha)
            sh = rocha.copy()
            face = np.zeros_like(rocha)
            for k in range(1, face_h + 1):
                sh = np.roll(sh, -1, 0)
                sh[-1] = True
                face |= rocha & ~sh
            # face = rocha com chão em até face_h px abaixo
            topo = rocha & ~face
            if caverna:
                topo_cor = [(28, 20, 34), (34, 25, 40), (40, 30, 46)]
                face_cor = [(62, 48, 66), (84, 64, 84), (104, 82, 100), (126, 104, 118)]
            elif deserto:
                topo_cor = [(190, 122, 80), (200, 132, 86), (210, 144, 94)]
                face_cor = [(110, 58, 52), (140, 78, 60), (166, 98, 70), (190, 120, 82)]
            else:
                topo_cor = [(76, 160, 96), (86, 176, 100), (96, 186, 104)]
                face_cor = [(98, 62, 52), (126, 82, 62), (150, 102, 74), (176, 124, 88)]
            pal(topo, topo_cor, n1 * 0.7 + n2 * 0.2, [-1.3, 1.3])
            img[topo & (fino > 0.992)] = np.array(topo_cor[0]) * 0.85
            # Face: faixas horizontais (estratos) + rachaduras verticais.
            # Distância até a base da face (0 = embaixo).
            base = np.zeros(rocha.shape, np.int32)
            sh = rocha.copy()
            for k in range(1, face_h + 1):
                sh = np.roll(sh, -1, 0)
                sh[-1] = True
                base[(base == 0) & face & ~sh] = k
            estrato = (base + (n1 * 1.2).astype(int)) % 5
            fc = np.where(base <= 2, 0, np.where(base >= face_h - 1, 3, np.where(estrato < 2, 1, 2)))
            for i, c in enumerate(face_cor):
                img[face & (fc == i)] = c
            rach = face & (noise(H, W, seed_of(map_id, "rach"), 2.5) > 1.6) & (base > 2)
            img[rach] = np.array(face_cor[0]) * 0.9
            # Contorno escuro no topo e sombra no chão logo abaixo da face.
            borda = rocha & ~(np.roll(rocha, 1, 0) & np.roll(rocha, -1, 0) & np.roll(rocha, 1, 1) & np.roll(rocha, -1, 1))
            img[borda & topo] = OL
            chao_sombra = ~rocha & ~agua & ~vazio & (np.roll(rocha, 1, 0) | np.roll(rocha, 2, 0) | np.roll(rocha, 3, 0))
            img[chao_sombra] *= 0.72
            img[face & ~np.roll(rocha, -1, 0)] = OL

        # Bordas: grama com contorno escuro e sombrinha na areia/caminho abaixo.
        gb = grama & ~(np.roll(grama, 1, 0) & np.roll(grama, -1, 0) & np.roll(grama, 1, 1) & np.roll(grama, -1, 1))
        img[gb] = (60, 128, 68)
        abaixo_grama = (areia | cam) & np.roll(grama, 1, 0)
        img[abaixo_grama] *= 0.82
        # Plataformas sobre o abismo: face de pedra pendurada para baixo.
        if vazio.any():
            solo = ~vazio
            pend = np.zeros_like(vazio)
            sh = solo.copy()
            for k in range(1, 11):
                sh = np.roll(sh, 1, 0)
                sh[0] = False
                pend |= vazio & sh
            # Só a face logo abaixo, com estratos.
            dd = dist(solo, 12)
            camada = (dd + (n1 * 1).astype(int))
            for lim, c in ((3, (110, 80, 86)), (6, (86, 60, 70)), (9, (62, 42, 52)), (11, (40, 26, 36))):
                sel = pend & (camada < lim) & ~(img[..., 0] < 0)
                img[sel & (camada >= lim - 3)] = c
        # Contorno da água (beira).
        ab = agua & ~(np.roll(agua, 1, 0) & np.roll(agua, -1, 0) & np.roll(agua, 1, 1) & np.roll(agua, -1, 1))
        img[ab & (d_terra <= 1)] = (246, 252, 255)
        return np.clip(img, 0, 255).astype(np.uint8)

    # ------------------------------------------------------------------ estruturas
    def estruturas(self, base, g, estrut, map_id):
        h, w = len(g), len(g[0])
        grp = {",": ",", "*": ",", "W": "W", "=": "W", "H": "H", "J": "H", "D": "H"}

        def mask(x, y):
            c = grp.get(g[y][x], g[y][x])
            m = 0
            for bit, (dx, dy) in ((1, (0, -1)), (2, (1, 0)), (4, (0, 1)), (8, (-1, 0))):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < w and 0 <= yy < h):
                    continue
                n = g[yy][xx]
                if n in OBJETOS:
                    continue
                if grp.get(n, n) != c:
                    m |= bit
            return m
        # Sombra suave sob muros e casas.
        sombra = Image.new("RGBA", base.size, (0, 0, 0, 0))
        sp = sombra.load()
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if estrut[y, x] and ch in "#HJDgw" and y + 1 < h and not estrut[y + 1, x]:
                    for yy in range(4):
                        for xx in range(T):
                            sp[x * T + xx, (y + 1) * T + yy] = (20, 10, 30, 70 - yy * 15)
        base.alpha_composite(sombra)
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if not estrut[y, x] or ch == "#" and (map_id in PENHASCO or map_id in FORTALEZA):
                    continue
                ci = TILE_CHARS.find(ch)
                if ci < 0:
                    continue
                m = mask(x, y)
                tile = self.atlas.crop((ci * T, m * T, ci * T + T, m * T + T))
                if ch == "=":
                    base.alpha_composite(tile, (x * T, y * T))
                else:
                    base.paste(tile, (x * T, y * T), tile)
        flat = "".join("".join(r) for r in g)
        tema = "caverna" if flat.count("c") > flat.count(".") + flat.count(",") else (
            "deserto" if flat.count(".") > flat.count(",") else "cinza")
        for y in range(h):
            for x in range(w):
                ch = g[y][x]
                if ch == "r":
                    base.alpha_composite(pedra(tema, seed_of(map_id, x, y) % 9), (x * T, y * T))
                    continue
                if ch in OBJETOS and ch != "T":
                    oi = OBJETOS.index(ch)
                    o = self.obj.crop((oi * T, 0, oi * T + T, T))
                    base.alpha_composite(o, (x * T, y * T))
        return base

    def assar(self, map_id, data):
        rows = data["layout"]
        flat = "".join(rows)
        if "w" in flat and flat.count("f") + flat.count("P") > flat.count(".") + flat.count(",") + flat.count(":") + flat.count("W"):
            w = max(len(r) for r in rows)
            g = [list(r.ljust(w)) for r in rows]
            img = Image.new("RGBA", (w * T, len(rows) * T), (24, 16, 22, 255))
            return self.interior.desenhar(data, map_id, g, img)
        g, cls, estrut, caverna = self.classes(rows, map_id)
        px = self.campo(cls, map_id)
        flat = "".join(rows)
        deserto = flat.count(".") > flat.count(",")
        img = Image.fromarray(self.pintar(px, map_id, caverna, deserto)).convert("RGBA")
        return self.estruturas(img, g, estrut, map_id)


def main():
    args = sys.argv[1:]
    tileset = TILESET
    if "--tileset" in args:
        i = args.index("--tileset")
        tileset = args[i + 1]
        del args[i:i + 2]
    mapas, cen, out = args[:3]
    nomes = args[3:]
    a = Assador(cen, tileset)
    os.makedirs(out, exist_ok=True)
    for f in sorted(os.listdir(mapas)):
        if not f.endswith(".json") or (nomes and f[:-5] not in nomes):
            continue
        with open(os.path.join(mapas, f), encoding="utf-8") as fh:
            data = json.load(fh)
        a.assar(f[:-5], data).save(os.path.join(out, f[:-5] + ".png"), optimize=True)


if __name__ == "__main__":
    main()
