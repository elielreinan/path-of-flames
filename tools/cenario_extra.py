"""Peças desenhadas à mão (por código) para o assador: entrada de caverna, poço e estante contínua.
Estilo Sunnyside: contorno escuro, 3-4 tons, luz no alto à esquerda, sombra suave no chão.
"""
import hashlib

import numpy as np
from PIL import Image

T = 16
OL = (23, 20, 36, 255)

ROCHA_COR = {
    # topo (claro, médio), face (escura -> clara), aro da boca
    "deserto": [(210, 144, 94), (196, 130, 84), (110, 58, 52), (140, 78, 60), (166, 98, 70), (190, 120, 82), (226, 168, 112)],
    "verde": [(96, 186, 104), (86, 176, 100), (98, 62, 52), (126, 82, 62), (150, 102, 74), (176, 124, 88), (206, 160, 116)],
    "caverna": [(80, 64, 84), (68, 54, 72), (40, 30, 46), (62, 48, 66), (84, 64, 84), (106, 84, 104), (132, 112, 128)],
}


def _h(*a):
    return int(hashlib.md5(":".join(map(str, a)).encode()).hexdigest()[:8], 16)


def _contorno(dentro):
    """Pixels fora de 'dentro' encostados nele (sem dar a volta na borda da imagem)."""
    p = np.pad(dentro, 1)
    viz = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return viz & ~dentro


def _ruido(h, w, seed, period):
    rnd = np.random.default_rng(seed)
    gh, gw = int(h / period) + 3, int(w / period) + 3
    lat = rnd.uniform(-1, 1, (gh, gw))
    ys, xs = np.arange(h) / period, np.arange(w) / period
    y0, x0 = ys.astype(int), xs.astype(int)
    fy, fx = (ys - y0)[:, None], (xs - x0)[None, :]
    a, b = lat[y0][:, x0], lat[y0][:, x0 + 1]
    c, d = lat[y0 + 1][:, x0], lat[y0 + 1][:, x0 + 1]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


# ---------------------------------------------------------------------- caverna
def boca_caverna(larg_abertura, prof_px, tema, seed):
    """Sprite de um paredão de pedra com boca de caverna em arco virada para o sul.
    larg_abertura: largura do vão em px (múltiplo de 16); prof_px: altura do vão.
    Retorna (img, ox): ox = deslocamento x do vão dentro do sprite."""
    c = ROCHA_COR[tema]
    margem = 13
    W = larg_abertura + 2 * margem
    alt_vao = max(prof_px, 22)
    H = alt_vao + 14
    ys, xs = np.mgrid[0:H, 0:W]
    rnd = np.random.default_rng(seed)
    # Silhueta: ombros arredondados com borda irregular no topo.
    n = _ruido(1, W, seed, 5)[0] * 3
    cx = (W - 1) / 2
    ombro = np.abs(xs - cx) / (W / 2)
    topo = 2 + 9 * ombro ** 2.2 + n[None, :].repeat(H, 0)
    corpo = (ys >= topo) & (ys < H)
    # Vão em arco: retângulo + semicírculo no alto.
    ax0, ax1 = margem + 1, margem + larg_abertura - 2
    r = (ax1 - ax0 + 1) / 2
    acx = (ax0 + ax1) / 2
    y_arco = H - alt_vao + r
    vao = (xs >= ax0) & (xs <= ax1) & (ys >= y_arco)
    vao |= ((xs - acx) ** 2 + (ys - y_arco) ** 2 <= r * r) & (ys < y_arco)
    vao &= ys < H
    out = np.zeros((H, W, 4), np.uint8)
    # Face com estratos horizontais e luz da esquerda.
    estr = ((ys + (n[None, :] * 0.7).astype(int)) // 4) % 3
    luz = (xs < cx - larg_abertura / 2 - 3)
    face = corpo & ~vao
    cor = np.where(estr == 0, 4, np.where(estr == 1, 3, 4))
    cor = np.where(luz & (estr != 1), 5, cor)
    cor[ys >= H - 3] = 2
    for i in (2, 3, 4, 5):
        sel = face & (cor == i)
        out[sel, :3] = c[i]
        out[sel, 3] = 255
    # Faixa clara no topo (borda do platô).
    capa = corpo & (ys < topo + 3) & ~vao
    out[capa, :3] = c[0]
    out[capa & (ys < topo + 1.2), :3] = c[6]
    # Rachaduras.
    for _ in range(max(2, W // 12)):
        x0 = int(rnd.integers(2, W - 2))
        y0 = int(rnd.integers(int(H * 0.35), H - 4))
        for k in range(int(rnd.integers(2, 5))):
            yy, xx = y0 + k, x0 + (k // 2) * (1 if x0 % 2 else -1)
            if 0 <= yy < H and 0 <= xx < W and face[yy, xx]:
                out[yy, xx, :3] = c[2]
    # Escuridão do vão: mais fundo = mais escuro (para cima e para o centro).
    prof = (H - 1 - ys) / max(alt_vao, 1)
    centro = 1 - np.abs(xs - acx) / max(r, 1)
    esc = np.clip(prof * 0.95 + centro * 0.12, 0, 1)
    tons = [(74, 52, 68), (52, 36, 54), (34, 24, 40), (20, 14, 26), (12, 8, 18)]
    idx = np.clip((esc * len(tons)).astype(int), 0, len(tons) - 1)
    for i, t in enumerate(tons):
        sel = vao & (idx == i)
        out[sel, :3] = t
        out[sel, 3] = 255
    # Chão de terra entrando na caverna (base clara).
    base = vao & (ys >= H - 3)
    out[base, :3] = tons[0]
    # Aro de pedras em volta do arco.
    aro = _contorno(vao) & corpo
    aro2 = _contorno(vao | aro) & corpo & ~aro
    out[aro2, :3] = c[3]
    pedras = aro & ((xs + ys) % 5 != 0)
    out[aro, :3] = c[6]
    out[aro & ~pedras, :3] = c[3]
    out[aro, 3] = 255
    # Pedra-chave no alto do arco.
    ky = int(round(y_arco - r)) - 2
    kx = int(round(acx))
    for yy in range(ky - 1, ky + 3):
        for xx in range(kx - 2, kx + 2):
            if 0 <= yy < H and 0 <= xx < W and corpo[yy, xx]:
                out[yy, xx, :3] = c[6] if yy < ky + 1 else c[5]
                out[yy, xx, 3] = 255
    # Dentes de pedra pendurados (estalactites) no topo do vão.
    for k in range(3):
        sx = int(ax0 + 3 + (ax1 - ax0 - 6) * (k + 0.5) / 3 + rnd.integers(-1, 2))
        top = None
        for yy in range(H):
            if vao[yy, sx]:
                top = yy
                break
        if top is None:
            continue
        L = int(rnd.integers(2, 4))
        for i in range(L):
            if vao[top + i, sx]:
                out[top + i, sx, :3] = c[3]
                if i == 0 and vao[top, sx + 1]:
                    out[top, sx + 1, :3] = c[2]
    # Contorno externo e borda do vão.
    oc = _contorno(corpo)
    out[oc & (ys < H)] = OL
    out[_contorno(~vao) & vao & (ys < H - 1)] = (*tons[-1], 255)
    # Linha escura na base dos dois pilares.
    out[(ys == H - 1) & face] = OL
    return Image.fromarray(out, "RGBA"), margem


def pedrinhas(img, x, y, tema, seed, n=3):
    """Cascalho miúdo no chão (pontos x,y em px)."""
    c = ROCHA_COR[tema]
    rnd = np.random.default_rng(seed)
    px = img.load()
    for _ in range(n):
        ox, oy = int(x + rnd.integers(-6, 7)), int(y + rnd.integers(-2, 4))
        w = int(rnd.integers(2, 4))
        for dx in range(-1, w + 1):
            for dy in range(-1, 2):
                xx, yy = ox + dx, oy + dy
                if 0 <= xx < img.width and 0 <= yy < img.height:
                    borda = dx in (-1, w) or dy != 0
                    px[xx, yy] = OL if borda else (*c[5], 255)
        if 0 <= ox < img.width and 0 <= oy < img.height:
            px[ox, oy] = (*c[6], 255)


def boca_lateral(altura_px, tema, seed, lado="oeste"):
    """Entrada de caverna na borda do mapa (vista de cima): paredão com fenda escura que some na borda."""
    c = ROCHA_COR[tema]
    W = 25
    H = altura_px + 30
    ys, xs = np.mgrid[0:H, 0:W]
    n = _ruido(H, 1, seed, 6)[:, 0] * 2.5
    # Rocha encostada na borda (x pequeno), borda leste irregular.
    lim = 20 + n[:, None].repeat(W, 1) - 4 * (np.abs(ys - H / 2) / (H / 2)) ** 3
    rocha = xs < lim
    vao_y0, vao_y1 = 15, 15 + altura_px
    # Fenda: semi-elipse aberta para leste.
    cy = (vao_y0 + vao_y1 - 1) / 2
    ry = (vao_y1 - vao_y0) / 2
    vao = ((xs / (lim + 1)) ** 2 * 0.0 + ((ys - cy) / ry) ** 2 <= 1) & (xs < lim)
    out = np.zeros((H, W, 4), np.uint8)
    face = rocha & ~vao
    estr = (xs // 3 + (n[:, None] * 0.5).astype(int)) % 3
    cor = np.where(estr == 0, 4, np.where(estr == 1, 5, 3))
    cor[ys < 3] = 0
    for i in (0, 3, 4, 5):
        sel = face & (cor == i)
        out[sel, :3] = c[i]
        out[sel, 3] = 255
    # Escuridão: mais escura perto da borda (oeste).
    esc = np.clip(1 - xs / np.maximum(lim, 1), 0, 1) * 0.8 + 0.25 * (1 - np.abs(ys - cy) / ry)
    tons = [(74, 52, 68), (52, 36, 54), (34, 24, 40), (20, 14, 26), (12, 8, 18)]
    idx = np.clip((esc * len(tons)).astype(int), 0, len(tons) - 1)
    for i, t in enumerate(tons):
        sel = vao & (idx == i)
        out[sel, :3] = t
        out[sel, 3] = 255
    aro = _contorno(vao) & rocha
    out[aro, :3] = c[6]
    out[aro & ((xs + ys) % 4 == 0), :3] = c[3]
    out[aro, 3] = 255
    oc = _contorno(rocha) & (xs > 0)
    out[oc] = OL
    img = Image.fromarray(out, "RGBA")
    if lado == "leste":
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    return img, 15


# ---------------------------------------------------------------------- poço
def poco(tema="deserto"):
    """Poço de pedra 26x34 com telhadinho, manivela, corda e balde. Pé no centro de baixo."""
    W, H = 26, 34
    im = np.zeros((H, W, 4), np.uint8)
    pedra = [(214, 200, 178), (182, 166, 146), (146, 130, 116), (104, 92, 90)] if tema != "deserto" else \
        [(232, 196, 150), (206, 166, 122), (170, 128, 96), (122, 86, 70)]
    madeira = [(196, 136, 88), (160, 104, 66), (116, 72, 50)]
    telha = [(206, 92, 68), (170, 64, 56), (124, 44, 48)]
    agua = [(40, 108, 180), (24, 78, 150), (150, 214, 236)]

    def px(x, y, c):
        if 0 <= x < W and 0 <= y < H:
            im[y, x, :3] = c[:3]
            im[y, x, 3] = 255

    ys, xs = np.mgrid[0:H, 0:W]
    cx = 12.5
    # Sombra no chão.
    sh = ((xs - cx) / 13) ** 2 + ((ys - 31.5) / 2.6) ** 2 < 1
    im[sh] = (30, 16, 30, 80)
    # Parede cilíndrica (frente) de pedras: y 21..31.
    cil = (np.abs(xs - cx) <= 10.5) & (ys >= 21) & (ys <= 31)
    linha = (ys - 21) // 4
    junta = ((xs + linha * 3) % 6 == 0) | ((ys - 21) % 4 == 0)
    tom = np.where(xs < cx - 4, 0, np.where(xs > cx + 5, 2, 1))
    for i in range(3):
        sel = cil & (tom == i)
        im[sel, :3] = pedra[i]
        im[sel, 3] = 255
    im[cil & junta, :3] = pedra[3]
    # Borda do poço (elipse) e água dentro: centro y=20.
    rim = ((xs - cx) / 11) ** 2 + ((ys - 20) / 4.6) ** 2 <= 1
    dentro = ((xs - cx) / 8) ** 2 + ((ys - 20) / 2.8) ** 2 <= 1
    im[rim & ~dentro, :3] = pedra[0]
    im[rim & ~dentro & (ys > 20), :3] = pedra[1]
    im[rim, 3] = 255
    im[dentro, :3] = agua[1]
    im[dentro & (ys >= 20), :3] = agua[0]
    im[dentro & (ys == 19) & (np.abs(xs - cx + 3) < 2), :3] = agua[2]
    # Contornos.
    corpo = rim | cil
    im[_contorno(corpo)] = OL
    im[_contorno(~dentro) & dentro & (ys < 20)] = OL
    # Postes de madeira (x=2..3 e x=22..23), y 6..22.
    for x0 in (2, 21):
        for y in range(6, 23):
            px(x0, y, madeira[1])
            px(x0 + 1, y, madeira[2])
            px(x0 - 1, y, OL)
            px(x0 + 2, y, OL)
    # Manivela (viga) y=10.
    for x in range(3, 22):
        px(x, 10, madeira[0])
        px(x, 11, madeira[2])
    px(23, 9, madeira[0]); px(24, 9, madeira[0]); px(24, 10, madeira[2]); px(24, 11, madeira[2])
    for x in range(3, 22):
        px(x, 9, OL); px(x, 12, OL)
    # Corda e balde.
    for y in range(12, 17):
        px(12, y, (220, 196, 150))
    for y in range(16, 20):
        for x in range(10, 15):
            px(x, y, madeira[1] if x < 13 else madeira[2])
    for x in range(10, 15):
        px(x, 16, (150, 150, 160))
    for y in range(16, 20):
        px(9, y, OL); px(15, y, OL)
    for x in range(9, 16):
        px(x, 20, OL)
    # Telhado de duas águas: y 0..7.
    for y in range(0, 8):
        meia = 4 + y * 1.4
        for x in range(int(cx - meia), int(cx + meia) + 1):
            c = telha[0] if (x + y) % 3 else telha[1]
            if y >= 6:
                c = telha[2]
            px(x, y, c)
        px(int(cx - meia) - 1, y, OL)
        px(int(cx + meia) + 1, y, OL)
    for x in range(int(cx - 4), int(cx + 5)):
        px(x, -1 + 1, OL) if False else None
    for x in range(int(cx - 4) - 1, int(cx + 4) + 2):
        px(x, 0, OL)
    for x in range(int(cx - 13.8) - 1, int(cx + 13.8) + 2):
        px(x, 8, OL)
    return Image.fromarray(im, "RGBA")


# ---------------------------------------------------------------------- estante
LIVROS = [(178, 52, 60), (52, 92, 170), (60, 132, 90), (214, 168, 70), (150, 80, 150), (226, 120, 60), (90, 160, 180), (226, 214, 190)]


def estante(larg_px, seed, alt=24, cheia=1.0):
    """Estante de madeira contínua com livros coloridos em 3 prateleiras (vista de frente)."""
    W, H = larg_px, alt
    rnd = np.random.default_rng(seed)
    im = np.zeros((H, W, 4), np.uint8)
    mad = [(176, 116, 74), (144, 92, 60), (104, 64, 46), (82, 50, 40)]
    im[:, :, :3] = mad[1]
    im[:, :, 3] = 255
    im[0:3, :, :3] = mad[0]
    im[H - 2:, :, :3] = mad[2]
    nprat = 3 if H >= 22 else 2
    topo, base = 4, H - 3
    passo = (base - topo) / nprat
    for p in range(nprat):
        y0 = int(topo + p * passo)
        y1 = int(topo + (p + 1) * passo) - 1
        im[y0:y1, 2:W - 2, :3] = mad[3]
        x = 2
        while x < W - 3:
            if rnd.random() > cheia and x < W - 6:
                x += int(rnd.integers(2, 5))
                continue
            bw = int(rnd.integers(1, 3))
            alt_l = int(rnd.integers(max(2, y1 - y0 - 3), y1 - y0 + 1))
            cor = LIVROS[int(rnd.integers(0, len(LIVROS)))]
            for xx in range(x, min(x + bw, W - 2)):
                im[y1 - alt_l:y1, xx, :3] = cor
                im[y1 - alt_l, xx, :3] = tuple(min(255, v + 40) for v in cor)
            x += bw
            if rnd.random() < 0.12:
                x += 1
        im[y1, 1:W - 1, :3] = mad[0]
    # Divisórias verticais a cada 16 px.
    for xx in range(0, W, 16):
        im[:, xx:xx + 2, :3] = mad[2]
        im[:, xx, :3] = mad[0]
    im[:, W - 2:, :3] = mad[2]
    # Contorno.
    im[0, :] = OL
    im[H - 1, :] = OL
    im[:, 0] = OL
    im[:, W - 1] = OL
    return Image.fromarray(im, "RGBA")


def trono(seed=0):
    """Trono dourado com almofada vermelha, 22x30."""
    W, H = 22, 30
    im = np.zeros((H, W, 4), np.uint8)
    ouro = [(250, 214, 100), (226, 176, 70), (176, 120, 50)]
    verm = [(196, 56, 64), (150, 36, 52)]
    ys, xs = np.mgrid[0:H, 0:W]
    encosto = (xs >= 3) & (xs <= 18) & (ys >= 2) & (ys <= 20)
    arco = ((xs - 10.5) / 8) ** 2 + ((ys - 6) / 6) ** 2 <= 1
    corpo = (encosto & (ys >= 6)) | arco
    assento = (xs >= 1) & (xs <= 20) & (ys >= 18) & (ys <= 26)
    pes = ((xs <= 3) | (xs >= 18)) & (ys >= 26) & (ys <= 28) & (xs >= 1) & (xs <= 20)
    tudo = corpo | assento | pes
    im[tudo, :3] = ouro[1]
    im[tudo, 3] = 255
    im[tudo & (xs < 6), :3] = ouro[0]
    im[tudo & (xs > 15), :3] = ouro[2]
    almof = (xs >= 6) & (xs <= 15) & (ys >= 7) & (ys <= 19) & corpo
    im[almof, :3] = verm[0]
    im[almof & (xs > 12), :3] = verm[1]
    seat = (xs >= 3) & (xs <= 18) & (ys >= 19) & (ys <= 21)
    im[seat, :3] = verm[0]
    # Joia no alto.
    for (x, y) in ((10, 2), (11, 2), (10, 3), (11, 3)):
        im[y, x, :3] = (90, 200, 220)
    im[_contorno(tudo)] = OL
    sh = Image.new("RGBA", (W, H + 3), (0, 0, 0, 0))
    out = Image.fromarray(im, "RGBA")
    return out
