"""Ícones dos itens para a bolsa em grade (estilo Resident Evil).
Cada célula da grade tem 16x16 de arte: uma espada que ocupa 1x3 células tem 16x48.
Uso: python3 tools/gerar_icones.py  (na pasta game/)
"""
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "itens")
os.makedirs(OUT, exist_ok=True)
OUTLINE = (30, 20, 16, 255)


def hexa(h, a=255):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (c[3],)


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))


def outline(img):
    """Contorno escuro de 1 px em volta de tudo que não é transparente."""
    w, h = img.size
    src = img.load()
    out = img.copy()
    dst = out.load()
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0 and any(0 <= x + dx < w and 0 <= y + dy < h and src[x + dx, y + dy][3] > 0
                                         for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                dst[x, y] = OUTLINE
    return out


def sword(name, blade, guard, grip, curved=False, glow=None, runes=None, wood=False):
    img = Image.new("RGBA", (16, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    b, g, gr = hexa(blade), hexa(guard), hexa(grip)
    if glow:
        d.rectangle([5, 3, 10, 33], fill=hexa(glow, 90))
    for y in range(4, 33):
        off = int(((33 - y) / 29.0) ** 2 * 3) if curved else 0
        d.line([(7 + off, y), (8 + off, y)], fill=b)
        d.point((7 + off, y), fill=shade(b, 1.25))
        if not wood:
            d.point((9 + off, y), fill=shade(b, 0.8))
    tip_off = 3 if curved else 0
    d.point((7 + tip_off, 3), fill=b)
    if runes:
        for y in range(10, 30, 5):
            d.point((8, y), fill=hexa(runes))
    d.rectangle([3, 33, 12, 35], fill=g)
    d.line([(3, 33), (12, 33)], fill=shade(g, 1.3))
    d.rectangle([7, 36, 8, 42], fill=gr)
    for y in range(37, 42, 2):
        d.line([(7, y), (8, y)], fill=shade(gr, 0.7))
    d.rectangle([6, 43, 9, 45], fill=g)
    save(outline(img), name)


def armor(name, body, trim, metal=False, scales=False):
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c, t = hexa(body), hexa(trim)
    d.polygon([(6, 6), (12, 4), (20, 4), (26, 6), (29, 14), (24, 16), (24, 28), (8, 28), (8, 16), (3, 14)], fill=c)
    d.polygon([(12, 4), (16, 9), (20, 4)], fill=shade(c, 0.6))
    d.line([(8, 27), (24, 27)], fill=t, width=2)
    d.line([(16, 10), (16, 26)], fill=shade(c, 0.8))
    if metal:
        for y in range(11, 26, 3):
            d.line([(9, y), (23, y)], fill=shade(c, 1.2))
    if scales:
        for y in range(11, 26, 3):
            for x in range(9 + (y % 2) * 2, 24, 4):
                d.arc([x, y, x + 3, y + 3], 0, 180, fill=shade(c, 0.7))
    d.line([(6, 6), (3, 14)], fill=t)
    d.line([(26, 6), (29, 14)], fill=t)
    d.rectangle([9, 18, 23, 19], fill=t)
    save(outline(img), name)


def small(name, draw, size=(16, 16)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw(ImageDraw.Draw(img))
    save(outline(img), name)


sword("espada_madeira", "#a8743a", "#7a4a20", "#5a3a1a", wood=True)
sword("espada_bronze", "#d89a4a", "#a0602a", "#5a3a1a")
sword("espada_ferro", "#b8c0c8", "#6a6a72", "#4a2a1a")
sword("cimitarra", "#d8dce0", "#c0a040", "#6a2a1a", curved=True)
sword("lamina_coral", "#f08a8a", "#e0e0d0", "#3a6a8a")
sword("espada_vento", "#9ae0d8", "#4a8a80", "#3a3a5a", glow="#bff8f0")
sword("lamina_qadim", "#e8d48a", "#a08030", "#3a2a1a", runes="#40c0ff")
sword("espada_sal", "#f4f4f4", "#8a9aaa", "#2a2a3a")
sword("chama_de_kadir", "#ffb040", "#c03018", "#3a1a10", glow="#ff6020", runes="#fff0a0")

armor("tunica_couro", "#9a6a3a", "#5a3a1a")
armor("cota_malha", "#9aa2aa", "#5a5a62", metal=True)
armor("armadura_coral", "#e0807a", "#f0e0c0", scales=True)
armor("armadura_vento", "#6ab0a8", "#e0f0f0", metal=True)
armor("armadura_sal", "#e8eef4", "#7a8a9a", metal=True)

small("pao", lambda d: (d.ellipse([2, 5, 13, 12], fill=hexa("#d8a050")), d.line([(5, 7), (7, 9)], fill=hexa("#a06a2a")),
                        d.line([(8, 6), (10, 8)], fill=hexa("#a06a2a"))))
small("tamara", lambda d: (d.ellipse([3, 6, 8, 13], fill=hexa("#7a3a1a")), d.ellipse([8, 5, 13, 12], fill=hexa("#8a4a20")),
                           d.line([(8, 2), (8, 6)], fill=hexa("#4a8a3a"))))
small("pele_cobra", lambda d: (d.polygon([(2, 3), (13, 2), (14, 13), (3, 14)], fill=hexa("#6a9a4a")),
                               [d.point((x, y), fill=hexa("#3a6a2a")) for x in range(4, 13, 3) for y in range(4, 13, 3)]))
small("asa_morcego", lambda d: d.polygon([(1, 6), (8, 3), (15, 6), (12, 9), (10, 7), (8, 11), (6, 7), (4, 9)], fill=hexa("#4a3a5a")))
small("lenco_bandido", lambda d: (d.polygon([(2, 3), (14, 3), (8, 14)], fill=hexa("#b03030")),
                                  d.point((6, 6), fill=hexa("#f0f0f0")), d.point((10, 6), fill=hexa("#f0f0f0"))))
small("placa_aco", lambda d: (d.rectangle([2, 3, 13, 12], fill=hexa("#7a7a82")), d.line([(3, 4), (12, 4)], fill=hexa("#b0b0b8")),
                              d.point((4, 10), fill=hexa("#3a3a3a")), d.point((11, 10), fill=hexa("#3a3a3a"))))
small("carta", lambda d: (d.rectangle([1, 4, 14, 12], fill=hexa("#f0e6c8")), d.line([(1, 4), (8, 9), (14, 4)], fill=hexa("#a08a60")),
                          d.ellipse([6, 8, 9, 11], fill=hexa("#b02020"))))
small("pergaminho", lambda d: (d.rectangle([3, 3, 12, 12], fill=hexa("#e8d8a8")), d.rectangle([2, 2, 13, 3], fill=hexa("#a07a40")),
                               d.rectangle([2, 12, 13, 13], fill=hexa("#a07a40")), d.ellipse([6, 6, 9, 9], fill=hexa("#ff7020"))))
small("amuleto", lambda d: (d.arc([3, 1, 12, 9], 180, 360, fill=hexa("#c0a040")), d.ellipse([4, 6, 11, 13], fill=hexa("#e0b030")),
                            d.ellipse([6, 8, 9, 11], fill=hexa("#e03020"))))
small("mapa", lambda d: (d.rectangle([2, 3, 13, 12], fill=hexa("#e0c890")), d.line([(4, 10), (7, 6), (10, 8)], fill=hexa("#8a6a3a")),
                         d.line([(9, 4), (12, 7)], fill=hexa("#c02020")), d.line([(12, 4), (9, 7)], fill=hexa("#c02020"))))
small("cantil", lambda d: (d.ellipse([3, 9, 12, 28], fill=hexa("#8a5a30")), d.rectangle([6, 4, 9, 9], fill=hexa("#6a4020")),
                           d.line([(4, 14), (11, 14)], fill=hexa("#5a3a1a"))), size=(16, 32))
small("bolsa", lambda d: (d.ellipse([2, 4, 13, 14], fill=hexa("#8a5a30")), d.rectangle([5, 2, 10, 5], fill=hexa("#6a4020")),
                          d.line([(4, 8), (11, 8)], fill=hexa("#c0a060"))))
small("carne_seca", lambda d: (d.polygon([(2, 6), (10, 2), (14, 8), (6, 13)], fill=hexa("#9a3a2a")),
                               d.line([(4, 7), (10, 4)], fill=hexa("#d07a5a")), d.line([(6, 10), (12, 7)], fill=hexa("#d07a5a"))))
small("apito_camelo", lambda d: (d.rectangle([2, 6, 11, 10], fill=hexa("#c0a060")), d.ellipse([9, 4, 14, 11], fill=hexa("#d8b870")),
                                 d.point((5, 8), fill=hexa("#5a3a1a")), d.line([(1, 8), (2, 8)], fill=hexa("#8a6a3a"))))
small("olho_zazu", lambda d: (d.ellipse([2, 4, 13, 12], fill=hexa("#e8e0d0")), d.ellipse([5, 5, 10, 11], fill=hexa("#5a3a9a")),
                              d.ellipse([7, 7, 8, 9], fill=hexa("#101010")), d.point((6, 6), fill=hexa("#ffffff"))))
print("ícones gerados em", OUT)
