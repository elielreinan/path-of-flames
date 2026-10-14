"""Gera as folhas do personagem montado por partes (cabeça, corpo, espada, escudo).

Arte original do Ifrit Legend, desenhada por código. Layout ("formato Brasas"):
- Cada recorte tem 32x32 px.
- Colunas = direções, nesta ordem: baixo, esquerda, cima, direita.
- cabeca.png: 1 linha (128x32).
- corpo.png: linhas = poses: parado, andar1..andar4, golpe1..golpe3 (128x256).
- espada.png: linhas = golpe1..golpe3, mais "guardada" (128x128).
- escudo.png: 1 linha (128x32).
O personagem montado ocupa 32x48: cabeça em y=0, corpo em y=16.

Uso: python3 tools/gerar_paperdoll.py  (gera assets/personagens/<id>/ e uma prévia)
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DIRS = ["baixo", "esquerda", "cima", "direita"]
POSES = ["parado", "andar1", "andar2", "andar3", "andar4", "golpe1", "golpe2", "golpe3"]
CELL = 32
OUTLINE = (34, 20, 18, 255)

IFRIT = {
    "pele": (240, 190, 140), "pele_sombra": (205, 145, 100),
    "cabelo": (70, 40, 28), "cabelo_luz": (110, 66, 40),
    "faixa": (205, 40, 40), "faixa_luz": (240, 90, 70),
    "olho": (30, 24, 40), "boca": (170, 80, 70),
    "roupa": (40, 90, 175), "roupa_luz": (70, 130, 215), "roupa_sombra": (28, 60, 125),
    "cinto": (235, 190, 60), "calca": (120, 80, 50), "calca_sombra": (90, 58, 36),
    "bota": (60, 38, 28), "lamina": (215, 225, 235), "lamina_sombra": (150, 165, 185),
    "cabo": (110, 70, 40), "guarda": (230, 180, 60),
    "escudo": (150, 95, 50), "escudo_luz": (185, 125, 70), "aro": (190, 195, 205),
}


class Cell:
    def __init__(self):
        self.img = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
        self.px = self.img.load()

    def dot(self, x, y, c):
        if 0 <= x < CELL and 0 <= y < CELL:
            self.px[x, y] = c + (255,) if len(c) == 3 else c

    def rect(self, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.dot(xx, yy, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((xx + 0.5 - cx) / rx) ** 2 + ((yy + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.dot(xx, yy, c)

    def outline(self):
        """Contorno escuro de 1 px em volta de tudo que não é transparente."""
        src = self.img.copy().load()
        for y in range(CELL):
            for x in range(CELL):
                if src[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < CELL and 0 <= ny < CELL and src[nx, ny][3] > 0 and src[nx, ny] != OUTLINE:
                            self.px[x, y] = OUTLINE
                            break
        return self

    def flipped(self):
        c = Cell()
        c.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        c.px = c.img.load()
        return c


# ---------- Cabeça ----------

def head(p, d):
    c = Cell()
    if d == "baixo":
        c.ellipse(16, 18, 9.5, 9.5, p["pele"])
        c.rect(7, 22, 18, 3, p["pele"])
        c.ellipse(16, 25, 7, 3, p["pele"])
        c.rect(9, 25, 14, 2, p["pele_sombra"])
        c.rect(5, 16, 2, 4, p["pele"]); c.rect(25, 16, 2, 4, p["pele"])
        # Cabelo e franja.
        c.ellipse(16, 12, 11, 8, p["cabelo"])
        c.rect(6, 12, 3, 6, p["cabelo"]); c.rect(23, 12, 3, 6, p["cabelo"])
        for x, h in ((9, 4), (12, 5), (15, 4), (18, 5), (21, 4)):
            c.rect(x, 13, 3, h - 2, p["cabelo"])
        c.rect(10, 6, 8, 2, p["cabelo_luz"])
        # Faixa vermelha.
        c.rect(6, 11, 20, 3, p["faixa"]); c.rect(8, 11, 10, 1, p["faixa_luz"])
        # Olhos, sobrancelhas e boca.
        for x in (11, 19):
            c.rect(x, 18, 2, 4, p["olho"]); c.dot(x, 18, (255, 255, 255))
        c.rect(10, 16, 4, 1, p["cabelo"]); c.rect(18, 16, 4, 1, p["cabelo"])
        c.rect(15, 24, 3, 1, p["boca"])
    elif d == "cima":
        c.ellipse(16, 18, 9.5, 9.5, p["cabelo"])
        c.rect(7, 20, 18, 5, p["cabelo"])
        c.ellipse(16, 12, 11, 8, p["cabelo"])
        c.rect(5, 16, 2, 4, p["pele"]); c.rect(25, 16, 2, 4, p["pele"])
        c.rect(10, 6, 12, 2, p["cabelo_luz"]); c.rect(12, 16, 8, 1, p["cabelo_luz"])
        c.rect(6, 11, 20, 3, p["faixa"])
        # Nó e pontas da faixa.
        c.rect(14, 11, 4, 4, p["faixa_luz"])
        c.rect(13, 15, 2, 6, p["faixa"]); c.rect(17, 15, 2, 7, p["faixa"])
        c.rect(9, 25, 14, 2, p["pele_sombra"])
    else:  # esquerda (a direita é o espelho)
        c.ellipse(15, 18, 9, 9.5, p["pele"])
        c.rect(7, 21, 12, 4, p["pele"])
        c.ellipse(12, 25, 6, 2.5, p["pele"])
        c.rect(9, 25, 10, 2, p["pele_sombra"])
        c.dot(5, 20, p["pele"]); c.dot(6, 21, p["pele"])  # nariz
        c.ellipse(17, 12, 11, 8, p["cabelo"])
        c.rect(16, 12, 10, 12, p["cabelo"])
        c.rect(7, 13, 3, 3, p["cabelo"]); c.rect(10, 13, 3, 4, p["cabelo"])
        c.rect(12, 6, 9, 2, p["cabelo_luz"])
        c.rect(17, 17, 3, 4, p["pele"]); c.dot(18, 18, p["pele_sombra"])  # orelha
        c.rect(6, 11, 21, 3, p["faixa"]); c.rect(8, 11, 8, 1, p["faixa_luz"])
        c.rect(25, 12, 4, 2, p["faixa"]); c.rect(27, 14, 3, 2, p["faixa"]); c.rect(26, 16, 2, 2, p["faixa_luz"])
        c.rect(8, 18, 2, 4, p["olho"]); c.dot(8, 18, (255, 255, 255))
        c.rect(7, 16, 4, 1, p["cabelo"])
        c.rect(7, 24, 2, 1, p["boca"])
    return c.outline()


# ---------- Corpo ----------

def leg(c, p, x, y, length, w=4):
    c.rect(x, y, w, length, p["calca"])
    c.rect(x + w - 1, y, 1, length, p["calca_sombra"])
    c.rect(x - (1 if w == 4 else 0), y + length, w + 1, 3, p["bota"])


def body(p, d, pose):
    c = Cell()
    walk = {"andar1": 1, "andar2": 0, "andar3": -1, "andar4": 0}.get(pose, 0)
    bob = 1 if pose in ("andar2", "andar4") else 0
    strike = {"golpe1": 1, "golpe2": 2, "golpe3": 3}.get(pose, 0)
    top = 10 + bob
    if d in ("baixo", "cima"):
        # Pernas: no andar, uma encolhe enquanto a outra estica.
        leg(c, p, 11, top + 14, 4 - max(walk, 0) * 2)
        leg(c, p, 17, top + 14, 4 - max(-walk, 0) * 2)
        # Tronco.
        c.rect(14, top - 1, 4, 2, p["pele"] if d == "baixo" else p["cabelo"])
        c.rect(10, top + 1, 12, 13, p["roupa"])
        c.rect(10, top + 1, 2, 13, p["roupa_luz"]); c.rect(20, top + 1, 2, 13, p["roupa_sombra"])
        c.rect(10, top + 9, 12, 2, p["cinto"])
        if d == "baixo":
            c.rect(15, top + 1, 2, 4, p["roupa_sombra"])  # gola
            c.rect(15, top + 9, 2, 2, p["faixa"])  # fivela
        # Braços balançando ao contrário das pernas; no golpe o braço da espada sobe.
        arm_l = -walk
        arm_r = walk if not strike else -3 + strike
        c.rect(7, top + 2 + arm_l, 3, 8, p["roupa"]); c.rect(7, top + 10 + arm_l, 3, 3, p["pele"])
        c.rect(22, top + 2 + arm_r, 3, 8, p["roupa_sombra"]); c.rect(22, top + 10 + arm_r, 3, 3, p["pele"])
    else:  # esquerda
        # Pernas abrindo para frente e para trás.
        front, back = (-3 * walk, 3 * walk)
        leg(c, p, 14 + back, top + 14, 4, 4)
        leg(c, p, 13 + front, top + 14, 4, 4)
        c.rect(12, top + 1, 9, 13, p["roupa"])
        c.rect(12, top + 1, 2, 13, p["roupa_luz"]); c.rect(19, top + 1, 2, 13, p["roupa_sombra"])
        c.rect(12, top + 9, 9, 2, p["cinto"])
        c.rect(14, top - 1, 4, 2, p["pele"])
        if strike:
            # Braço estica para a frente (esquerda) no golpe.
            reach = [0, 3, 6, 7][strike]
            c.rect(14 - reach, top + 4, 6, 3, p["roupa_sombra"]); c.rect(11 - reach, top + 4, 3, 3, p["pele"])
        else:
            c.rect(15 + walk, top + 2, 3, 8, p["roupa_sombra"]); c.rect(15 + walk, top + 10, 3, 3, p["pele"])
    return c.outline()


# ---------- Espada e escudo ----------

def sword(p, angle_step):
    """Espada desenhada na diagonal; angle_step escolhe a pose do golpe."""
    c = Cell()
    pts = {
        0: [(22, 4 + i) for i in range(14)],               # erguida
        1: [(8 + i, 6 + i) for i in range(14)],            # diagonal
        2: [(4 + i, 18) for i in range(16)],               # deitada à frente
        3: [(26, 10 + i) for i in range(10)],              # guardada nas costas
    }[angle_step]
    for i, (x, y) in enumerate(pts):
        col = p["lamina"] if i < len(pts) - 4 else p["cabo"]
        c.dot(x, y, col)
        if angle_step == 1:
            c.dot(x + 1, y, p["lamina_sombra"] if i < len(pts) - 4 else p["cabo"])
        elif angle_step == 2:
            c.dot(x, y + 1, p["lamina_sombra"] if i < len(pts) - 4 else p["cabo"])
        else:
            c.dot(x + 1, y, p["lamina_sombra"] if i < len(pts) - 4 else p["cabo"])
    gx, gy = pts[len(pts) - 4]
    if angle_step == 2:
        c.rect(gx, gy - 2, 1, 5, p["guarda"])
    elif angle_step == 1:
        c.rect(gx - 1, gy + 1, 3, 1, p["guarda"]); c.rect(gx + 1, gy - 1, 1, 3, p["guarda"])
    else:
        c.rect(gx - 2, gy, 6, 1, p["guarda"])
    return c.outline()


def _turned(cell, angle, offset):
    c = Cell()
    img = cell.img.rotate(angle, resample=Image.NEAREST)
    c.img.paste(img, offset, img)
    c.px = c.img.load()
    return c


def sword_dirs(p, step):
    """A espada é desenhada para a esquerda; as outras direções giram ou espelham."""
    left = sword(p, step)
    if step == 3:
        return [left, left, left, left.flipped()]
    down = _turned(left, 90, (2, 2))
    up = _turned(left, -90, (-2, -6))
    return [down, left, up, left.flipped()]


def shield(p, d):
    c = Cell()
    if d == "baixo":
        c.ellipse(8, 22, 5, 6, p["aro"]); c.ellipse(8, 22, 4, 5, p["escudo"])
        c.rect(6, 18, 2, 6, p["escudo_luz"]); c.ellipse(8, 22, 1.5, 1.5, p["aro"])
    elif d == "cima":
        c.ellipse(24, 22, 5, 6, p["aro"]); c.ellipse(24, 22, 4, 5, p["escudo"])
        c.rect(23, 18, 2, 8, p["calca_sombra"])
    else:  # esquerda: escudo de lado no braço da frente
        c.ellipse(11, 22, 3, 6, p["aro"]); c.ellipse(11, 22, 2, 5, p["escudo_luz"])
    return c.outline()


def sheet(cells_by_row):
    img = Image.new("RGBA", (CELL * 4, CELL * len(cells_by_row)), (0, 0, 0, 0))
    for r, row in enumerate(cells_by_row):
        for col, cell in enumerate(row):
            img.paste(cell.img, (col * CELL, r * CELL), cell.img)
    return img


def by_dir(make):
    """Gera baixo, esquerda e cima; direita é o espelho da esquerda."""
    down, left, up = make("baixo"), make("esquerda"), make("cima")
    return [down, left, up, left.flipped()]


def build(char_id, p):
    out = ROOT / "assets" / "personagens" / char_id
    out.mkdir(parents=True, exist_ok=True)
    sheets = {
        "cabeca": sheet([by_dir(lambda d: head(p, d))]),
        "corpo": sheet([by_dir(lambda d, pose=pose: body(p, d, pose)) for pose in POSES]),
        "espada": sheet([sword_dirs(p, s) for s in (0, 1, 2, 3)]),
        "escudo": sheet([by_dir(lambda d: shield(p, d))]),
    }
    for name, img in sheets.items():
        img.save(out / f"{name}.png")
    return sheets


def compose(sheets, d, pose, sword_step=None, with_shield=True):
    """Monta um quadro 32x48 como o jogo faz (usado só na prévia)."""
    col = DIRS.index(d)
    frame = Image.new("RGBA", (CELL, 48), (0, 0, 0, 0))
    cut = lambda img, row: img.crop((col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL))
    behind = d == "cima"
    layers = []
    if sword_step is not None:
        layers.append(("espada", cut(sheets["espada"], sword_step), (0, 16), behind))
    if with_shield:
        layers.append(("escudo", cut(sheets["escudo"], 0), (0, 16), d != "baixo" and d != "esquerda"))
    for _, img, pos, back in layers:
        if back:
            frame.alpha_composite(img, pos)
    frame.alpha_composite(cut(sheets["corpo"], POSES.index(pose)), (0, 16))
    frame.alpha_composite(cut(sheets["cabeca"], 0), (0, 0))
    for _, img, pos, back in layers:
        if not back:
            frame.alpha_composite(img, pos)
    return frame


def preview(sheets, path, scale=5):
    rows = [[("parado", None)] * 1 + [(f"andar{i}", None) for i in range(1, 5)] + [("golpe1", 0), ("golpe2", 1), ("golpe3", 2)]]
    w, h = 8 * 34, 4 * 50
    img = Image.new("RGBA", (w, h), (233, 196, 140, 255))
    for r, d in enumerate(DIRS):
        for i, (pose, s) in enumerate(rows[0]):
            img.alpha_composite(compose(sheets, d, pose, s), (i * 34 + 1, r * 50 + 1))
    img.resize((w * scale, h * scale), Image.NEAREST).save(path)


if __name__ == "__main__":
    s = build("ifrit", IFRIT)
    preview(s, "/tmp/claude-0/paperdoll_preview.png")
    print("ok")
