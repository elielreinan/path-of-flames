"""Deixa os mapas com formas naturais (lagos, praias, cavernas e penhascos arredondados e irregulares).
Roda depois de montar os mapas (construir_mapas.build_all chama paisagem.build(MAPS) antes de salvar)
ou sozinho:  python3 tools/paisagem.py  (reescreve data/mapas/*.json).

Regras de segurança:
- Pontos importantes (spawns, NPCs, baús, placas, coletáveis, chefe, saídas, gatilhos, arena e destinos de
  cutscene) e a vizinhança deles nunca mudam.
- Uma mudança só fica se todos os pontos que se alcançavam continuam se alcançando, se nenhum gatilho passa
  a poder ser contornado e se nenhum caminho entre pontos importantes encurta mais que 2 tiles.
- Pontes ('=') e a água dos lados delas não mudam.
"""
import hashlib, json, os, random
from collections import deque

import numpy as np

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")
SOLID = set("#HRTWrmbXCS JKwhE") | set("FAVLONGjYZ")
# Mapas onde '#' é paredão de pedra natural (nas cidades '#' é muro e não mexe).
PENHASCO = {"desfiladeiro_sal", "trilha_penhascos"}
# Mapas cercados por uma fileira de pedras soltas: a fileira vira paredão de rocha.
BORDA_PEDRA = {"dunas_rubras", "canion_feras", "mar_de_areia", "estrada_caravanas", "estrada_norte"}


def _seed(map_id, salt):
    return int(hashlib.md5(f"{map_id}:{salt}".encode()).hexdigest()[:8], 16)


def _noise(h, w, seed, period=4.0, octaves=2):
    rnd = np.random.default_rng(seed)
    out = np.zeros((h, w))
    amp, total = 1.0, 0.0
    for _ in range(octaves):
        gh, gw = int(h / period) + 3, int(w / period) + 3
        lat = rnd.uniform(-1, 1, (gh, gw))
        ys = np.arange(h) / period
        xs = np.arange(w) / period
        y0 = np.floor(ys).astype(int)
        x0 = np.floor(xs).astype(int)
        fy = (ys - y0)[:, None]
        fx = (xs - x0)[None, :]
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        a = lat[y0][:, x0]
        b = lat[y0][:, x0 + 1]
        c = lat[y0 + 1][:, x0]
        d = lat[y0 + 1][:, x0 + 1]
        out += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy)
        total += amp
        amp *= 0.5
        period /= 2.0
    out /= total
    return out / max(out.std(), 1e-6) * 0.5


def _blur(m, sigma):
    r = max(1, int(sigma * 3))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    p = np.pad(m.astype(float), r, mode="edge")
    p = np.apply_along_axis(lambda v: np.convolve(v, k, mode="valid"), 1, p)
    p = np.apply_along_axis(lambda v: np.convolve(v, k, mode="valid"), 0, p)
    return p


def _amostra(m, dx, dy):
    h, w = m.shape
    ys, xs = np.mgrid[0:h, 0:w]
    sx = np.clip(xs + dx, 0, w - 1)
    sy = np.clip(ys + dy, 0, h - 1)
    x0 = np.floor(sx).astype(int)
    y0 = np.floor(sy).astype(int)
    x1 = np.minimum(x0 + 1, w - 1)
    y1 = np.minimum(y0 + 1, h - 1)
    fx = sx - x0
    fy = sy - y0
    return (m[y0, x0] * (1 - fx) + m[y0, x1] * fx) * (1 - fy) + (m[y1, x0] * (1 - fx) + m[y1, x1] * fx) * fy


class Mapa:
    def __init__(self, map_id, data, cut_points):
        self.id = map_id
        self.data = data
        self.g = [list(r) for r in data["layout"]]
        self.h = len(self.g)
        self.w = max(len(r) for r in self.g)
        for r in self.g:
            r.extend(" " * (self.w - len(r)))
        self.keys = []      # pontos que precisam continuar alcançáveis
        self.gatilhos = []  # áreas que não podem ser contornadas
        self.fixo = np.zeros((self.h, self.w), bool)
        d = data
        pts = list(d.get("spawns", {}).values())
        for k in ("npcs", "baus", "placas", "coletaveis", "empurraveis"):
            pts += [e["pos"] for e in d.get(k, []) if not e.get("nada")]
        if "chefe" in d:
            pts.append(d["chefe"]["pos"])
        for x, y in pts:
            self._fixa(x - 1, y - 1, 3, 3)
            self.keys.append((x, y))
        for s in d.get("saidas", []):
            x, y, w, h = s["area"]
            self._fixa(x - 1, y - 1, w + 2, h + 2)
            self.keys.append((x, y))
        for gt in d.get("gatilhos", []):
            x, y, w, h = gt["area"]
            self._fixa(x - 1, y - 1, w + 2, h + 2)
            self.keys.append((x, y))
            self.gatilhos.append([(xx, yy) for xx in range(x, x + w) for yy in range(y, y + h)])
        if "arena" in d:
            x, y, w, h = d["arena"]
            self._fixa(x - 1, y - 1, w + 2, h + 2)
        for x, y in cut_points:
            if 0 <= x < self.w and 0 <= y < self.h:
                self._fixa(x, y, 1, 1)
        for y in range(self.h):
            for x in range(self.w):
                if self.g[y][x] == "=":
                    self._fixa(x - 1, y - 1, 3, 3)
        self.spawns = [tuple(p) for p in d.get("spawns", {}).values()]
        self.keys = [k for k in self.keys if self._anda(*k)]

    def _fixa(self, x, y, w, h):
        self.fixo[max(0, y):max(0, y + h), max(0, x):max(0, x + w)] = True

    def _anda(self, x, y, g=None):
        g = g or self.g
        return 0 <= x < self.w and 0 <= y < self.h and g[y][x] not in SOLID

    def _bfs(self, start, bloqueio=()):
        dist = {start: 0}
        q = deque([start])
        bl = set(bloqueio)
        while q:
            x, y = q.popleft()
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if (nx, ny) not in dist and (nx, ny) not in bl and self._anda(nx, ny):
                    dist[(nx, ny)] = dist[(x, y)] + 1
                    q.append((nx, ny))
        return dist

    def _assinatura(self):
        """Fotografia da conectividade: quem alcança quem, distâncias a partir dos spawns e o efeito de cada gatilho."""
        comp = {}
        for k in self.keys:
            if k not in comp:
                dist = self._bfs(k)
                for k2 in self.keys:
                    if k2 in dist:
                        comp[k2] = k
        dists = {s: self._bfs(s) for s in self.spawns if self._anda(*s)}
        gat = []
        for cells in self.gatilhos:
            vis = set()
            for s in self.spawns:
                if self._anda(*s) and s not in cells:
                    vis |= {k for k in self.keys if k in self._bfs(s, cells)}
            gat.append(vis)
        return comp, dists, gat

    def _ok(self, base):
        comp0, d0, g0 = base
        comp1, d1, g1 = self._assinatura()
        for a in self.keys:
            for b in self.keys:
                if comp0.get(a) == comp0.get(b) and comp0.get(a) is not None and comp1.get(a) != comp1.get(b):
                    return False
        for s, dist in d0.items():
            for k in self.keys:
                if k in dist and dist[k] - d1.get(s, {}).get(k, 10 ** 6) > 2:
                    return False
                if k in dist and k not in d1.get(s, {}):
                    return False
        return all(a == b for a, b in zip(g0, g1))

    def aplica(self, mudancas):
        """mudancas: {(x, y): novo}. Aplica em grupos vizinhos e desfaz os grupos que quebram a conectividade."""
        if not mudancas:
            return 0
        base = self._assinatura()
        antes = {p: self.g[p[1]][p[0]] for p in mudancas}
        for (x, y), ch in mudancas.items():
            self.g[y][x] = ch
        if self._ok(base):
            return len(mudancas)
        for (x, y), ch in antes.items():
            self.g[y][x] = ch
        # Grupos de mudanças vizinhas, testados um a um.
        resto = set(mudancas)
        grupos = []
        while resto:
            p = resto.pop()
            grupo = [p]
            fila = [p]
            while fila:
                x, y = fila.pop()
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        q = (x + dx, y + dy)
                        if q in resto:
                            resto.remove(q)
                            grupo.append(q)
                            fila.append(q)
            grupos.append(grupo)
        feitas = 0
        for grupo in grupos:
            for x, y in grupo:
                self.g[y][x] = mudancas[(x, y)]
            if self._ok(base):
                feitas += len(grupo)
                continue
            for x, y in grupo:
                self.g[y][x] = antes[(x, y)]
            # O grupo quebrou algo: tenta célula por célula.
            for x, y in grupo:
                self.g[y][x] = mudancas[(x, y)]
                if self._ok(base):
                    feitas += 1
                else:
                    self.g[y][x] = antes[(x, y)]
        return feitas

    def vizinho_comum(self, x, y, aceitos, padrao):
        # Procura em anéis cada vez maiores até achar chão aceito.
        for r in range(1, 8):
            conta = {}
            for yy in range(y - r, y + r + 1):
                for xx in range(x - r, x + r + 1):
                    if 0 <= xx < self.w and 0 <= yy < self.h and self.g[yy][xx] in aceitos:
                        conta[self.g[yy][xx]] = conta.get(self.g[yy][xx], 0) + 1
            if conta:
                return max(conta, key=conta.get)
        return padrao

    def molda(self, dentro, natural, novo_dentro, chao, sigma, amp, period, salt, borda=1, conta=None, bias=0.0):
        """Remodela a região 'dentro' (conjunto de caracteres) contra os chãos 'natural'.
        novo_dentro: caractere usado quando um chão vira região; chao: caracteres possíveis quando a região vira chão.
        conta: caracteres fixos que contam como região no cálculo (ex.: ponte conta como água)."""
        conta = conta or ""
        mov = set(dentro) | set(natural)
        ind = np.array([[c in dentro or c in conta for c in r] for r in self.g], float)
        peso = np.array([[c in mov or c in conta for c in r] for r in self.g], float)
        pb = _blur(peso, sigma)
        campo = _blur(ind * peso, sigma) / np.maximum(pb, 1e-3)
        # Fora da área considerada o campo copia o vizinho válido mais próximo (evita "puxar" valor vazio).
        ok = pb > 0.25
        for _ in range(max(self.w, self.h)):
            if ok.all():
                break
            soma = np.zeros_like(campo)
            n = np.zeros_like(campo)
            for sy, sx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                v = np.roll(ok, (sy, sx), (0, 1))
                c = np.roll(campo, (sy, sx), (0, 1))
                soma += np.where(v, c, 0)
                n += v
            novo_ok = ~ok & (n > 0)
            campo[novo_ok] = soma[novo_ok] / n[novo_ok]
            ok = ok | novo_ok
        # Distorce o campo com ruído (deixa as margens onduladas) e soma um pouco de ruído fino.
        dx = amp * _noise(self.h, self.w, _seed(self.id, salt + "x"), period)
        dy = amp * _noise(self.h, self.w, _seed(self.id, salt + "y"), period)
        campo = _amostra(campo, dx, dy) + 0.12 * _noise(self.h, self.w, _seed(self.id, salt), 2.0) + bias
        novo = campo > 0.5
        # Tira pontinhos soltos: cada célula segue a maioria em volta.
        viz = np.zeros_like(campo)
        pv = np.pad(novo.astype(float), 1, mode="edge")
        for dy in (0, 1, 2):
            for dx in (0, 1, 2):
                viz += pv[dy:dy + self.h, dx:dx + self.w]
        novo = np.where(viz >= 6, True, np.where(viz <= 3, False, novo))
        mud = {}
        for y in range(self.h):
            for x in range(self.w):
                if self.fixo[y, x]:
                    continue
                if x < borda or y < borda or x >= self.w - borda or y >= self.h - borda:
                    continue
                c = self.g[y][x]
                if c not in mov:
                    continue
                # Não encosta em construções e objetos (caminho, ponte e árvores podem).
                viz8 = [self.g[yy][xx] for yy in range(max(0, y - 1), min(self.h, y + 2)) for xx in range(max(0, x - 1), min(self.w, x + 2))]
                if any(v not in mov and v not in "rCT*:=" + conta for v in viz8):
                    continue
                if c in dentro and not novo[y, x]:
                    mud[(x, y)] = self.vizinho_comum(x, y, chao, chao[0])
                elif c in natural and novo[y, x] and c not in dentro:
                    mud[(x, y)] = novo_dentro
        antes = {p: self.g[p[1]][p[0]] for p in mud}
        feitas = self.aplica(mud)
        # Desfaz mudanças que ficaram soltas (uma célula isolada de água, rocha ou chão).
        base = self._assinatura()
        for _ in range(2):
            for (x, y), orig in antes.items():
                c = self.g[y][x]
                if c == orig:
                    continue
                grupo = dentro if c in dentro else natural
                iguais = sum(1 for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1))
                             if 0 <= nx < self.w and 0 <= ny < self.h and (self.g[ny][nx] in grupo or self.g[ny][nx] in conta))
                if iguais <= 1:
                    self.g[y][x] = orig
                    if self._ok(base):
                        feitas -= 1
                    else:
                        self.g[y][x] = c
        return feitas

    def rows(self):
        return ["".join(r).rstrip(" ") if False else "".join(r) for r in self.g]


def _perto(m, chars, raio):
    ind = np.array([[c in chars for c in r] for r in m.g], bool)
    out = ind.copy()
    for _ in range(raio):
        o = out.copy()
        o[1:] |= out[:-1]
        o[:-1] |= out[1:]
        o[:, 1:] |= out[:, :-1]
        o[:, :-1] |= out[:, 1:]
        out = o
    return out


def _cutscene_points():
    pts = set()
    pasta = os.path.join(DATA, "cutscenes")
    if not os.path.isdir(pasta):
        return pts

    def walk(v):
        if isinstance(v, dict):
            for k, x in v.items():
                if k in ("para", "pos", "de") and isinstance(x, list) and len(x) == 2 and all(isinstance(i, int) for i in x):
                    pts.add(tuple(x))
                walk(x)
        elif isinstance(v, list):
            for x in v:
                walk(x)
    for f in os.listdir(pasta):
        if f.endswith(".json"):
            with open(os.path.join(pasta, f), encoding="utf-8") as fh:
                walk(json.load(fh))
    return pts


def organico(map_id, data, cut_points):
    if data.get("interior") or map_id.startswith("lar_") or data.get("organico"):
        return {}
    m = Mapa(map_id, data, cut_points)
    flat = "".join(data["layout"])
    feito = {}
    if map_id in BORDA_PEDRA:
        # Fileira de pedras na borda vira paredão contínuo (e ganha forma irregular abaixo).
        fila = deque((x, y) for y in range(m.h) for x in range(m.w)
                     if (x in (0, m.w - 1) or y in (0, m.h - 1)) and m.g[y][x] == "r")
        vis = set(fila)
        while fila:
            x, y = fila.popleft()
            m.g[y][x] = "X"
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < m.w and 0 <= ny < m.h and (nx, ny) not in vis and m.g[ny][nx] == "r":
                    vis.add((nx, ny))
                    fila.append((nx, ny))
        feito["borda"] = len(vis)
    chao_ext = ".,"
    if "X" in "".join("".join(r) for r in m.g):
        chao = "c" if flat.count("c") > flat.count(".") + flat.count(",") else ".,"
        feito["rocha"] = m.molda("X", chao + "*", "X", chao, sigma=0.9, amp=1.6, period=5.0, salt="X", borda=1)
    if map_id in PENHASCO:
        feito["penhasco"] = m.molda("#", ".,*", "#", ".,", sigma=0.9, amp=1.6, period=4.0, salt="#", borda=1)
    if " " in flat:
        feito["abismo"] = m.molda(" ", "c", " ", "c", sigma=0.9, amp=1.5, period=4.0, salt="v", borda=0)
    if "W" in flat:
        chao_agua = "c" if "c" in flat and flat.count("c") > flat.count(".") else chao_ext
        grande = flat.count("W") > 200
        pequena = flat.count("W") < 60
        feito["agua"] = m.molda("W", chao_agua + "*", "W", chao_agua, sigma=1.0 if not grande else 1.2,
                                amp=2.8 if not grande else 2.6, period=6.0 if not grande else 7.0, salt="W", borda=0,
                                conta="=", bias=-0.04 if grande else (0.3 if pequena else 0.16))
    if flat.count(",") > 150 and flat.count(".") > 150:
        # Grama e areia se misturam em manchas (não muda colisão).
        feito["grama"] = m.molda(",*", ".", ",", ".", sigma=1.2, amp=2.0, period=6.0, salt="g", borda=1)
    data["layout"] = m.rows()
    data["organico"] = True
    return feito


def build(MAPS):
    cut = _cutscene_points()
    for map_id, data in MAPS.items():
        organico(map_id, data, cut)
    import interiores
    interiores.build(MAPS, cut)


if __name__ == "__main__":
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    pasta = os.path.join(DATA, "mapas")
    MAPS = {}
    for f in sorted(os.listdir(pasta)):
        if f.endswith(".json"):
            with open(os.path.join(pasta, f), encoding="utf-8") as fh:
                MAPS[f[:-5]] = json.load(fh)
    cut = _cutscene_points()
    for map_id, data in MAPS.items():
        r = organico(map_id, data, cut)
        if r:
            print(map_id, r)
    import interiores
    interiores.build(MAPS, cut)
    for map_id, data in MAPS.items():
        with open(os.path.join(pasta, map_id + ".json"), "w", encoding="utf-8") as fh:
            json.dump(data, fh, ensure_ascii=False, indent=1)
