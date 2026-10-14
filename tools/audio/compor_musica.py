"""Compõe as músicas do Chamado das Brasas (maqams árabes, alaúde, ney, darbuka).

Uso: python3 compor_musica.py <pasta_saida>
Cada faixa em loop fecha sem emenda (reverberação circular). Saída em OGG.
Obra original gerada por código, liberada como CC0.
"""
import os
import sys
import numpy as np
from sintese import (Mix, write_ogg, freq, pluck, ney, drone, pad, doum, tek, riq, boom, SR)

# Maqams: graus em semitons a partir da tônica (0,5 = quarto de tom).
MAQAM = {
    "hijaz": [0, 1, 4, 5, 7, 8, 10],
    "bayati": [0, 1.5, 3, 5, 7, 8, 10],
    "rast": [0, 2, 3.5, 5, 7, 9, 10.5],
    "nahawand": [0, 2, 3, 5, 7, 8, 11],
    "kurd": [0, 1, 3, 5, 7, 8, 10],
    "saba": [0, 1.5, 3, 4, 7, 8, 10],
}

# Ritmos em semicolcheias por compasso de 4/4 (16 passos): D = doum, T = tek, k = ka leve.
RITMO = {
    "maqsum": "D.T.kTk.D.T.kTk.",
    "baladi": "D.D.kTk.D.T.kTk.",
    "masmudi": "D.D.k.T.D.k.T.k.",
    "ayoub": "D.kTD.T.D.kTD.T.",
    "leve": "D.......T.......",
    "batida": "D...T...D.D.T...",
    "nenhum": "................",
}


def degree(scale, tonic, d):
    """Grau d da escala (pode ser negativo ou passar da oitava)."""
    octave, idx = divmod(d, len(scale))
    return tonic + scale[idx] + 12 * octave


class Song:
    def __init__(self, name, maqam, tonic, bpm, bars, seed, loop=True):
        self.name, self.scale, self.tonic, self.bpm, self.bars = name, MAQAM[maqam], tonic, bpm, bars
        self.beat = 60.0 / bpm
        self.step = self.beat / 4
        self.bar = self.beat * 4
        self.loop = loop
        self.rng = np.random.default_rng(seed)
        tail = 0 if loop else 3.0
        self.mix = Mix(self.bar * bars + tail)

    def note(self, d, octave=0):
        return degree(self.scale, self.tonic + 12 * octave, d)

    # ----- melodia -----
    def motif(self, length_steps=32, start=0, span=(-2, 6), rest=0.15):
        """Motivo de 2 compassos: passos curtos na escala, notas de 1 a 4 semicolcheias."""
        rhythms = [[4, 2, 2, 4, 4], [2, 2, 4, 8], [4, 4, 8], [3, 1, 4, 4, 4], [2, 2, 2, 2, 8], [6, 2, 4, 4], [8, 4, 4]]
        notes = []
        pos = 0
        d = start
        while pos < length_steps:
            for dur in rhythms[self.rng.integers(len(rhythms))]:
                if pos >= length_steps:
                    break
                dur = min(dur, length_steps - pos)
                r = self.rng.random()
                move = 0 if r < 0.15 else (self.rng.choice([-1, 1]) if r < 0.75 else self.rng.choice([-2, 2, -3]))
                d = int(np.clip(d + move, span[0], span[1]))
                is_rest = self.rng.random() < rest and pos > 0
                notes.append((pos, dur, None if is_rest else d))
                pos += dur
        return notes

    def play_melody(self, notes, bar0, inst="oud", octave=0, gain=0.5, pan=0.0, ornament=True):
        for pos, dur, d in notes:
            if d is None:
                continue
            at = bar0 * self.bar + pos * self.step
            m = self.note(d, octave)
            if inst == "oud":
                length = max(dur * self.step * 1.6, 0.5)
                self.mix.add(pluck(freq(m), length, bright=1.0, nasal=1.4), at, gain, pan)
                # Trêmolo do alaúde em notas longas.
                if dur >= 8 and ornament:
                    for k in range(2, dur, 2):
                        self.mix.add(pluck(freq(m), 0.35, bright=0.8, nasal=1.4), at + k * self.step, gain * 0.45, pan)
            elif inst == "qanun":
                self.mix.add(pluck(freq(m), max(dur * self.step * 1.4, 0.4), bright=1.6, nasal=0.8, decay=3.0), at, gain, pan)
                if ornament and dur >= 4 and self.rng.random() < 0.4:
                    self.mix.add(pluck(freq(self.note(d + 1, octave)), 0.2, bright=1.6, decay=4), at - self.step * 0.5, gain * 0.4, pan)
            elif inst == "ney":
                length = dur * self.step * 1.02
                self.mix.add(ney(freq(m), length + 0.08), at, gain, pan)

    def drone(self, d=0, octave=-1, gain=0.12, fifth=True):
        total = self.bar * self.bars
        self.mix.add(drone(freq(self.note(d, octave)), total + 0.5), 0, gain, -0.2)
        if fifth:
            self.mix.add(drone(freq(self.note(4, octave)), total + 0.5), 0, gain * 0.55, 0.25)

    def pads(self, chords, octave=0, gain=0.18, bright=0.5):
        """chords: lista de (compasso, compassos de duração, graus)."""
        for bar0, length, degs in chords:
            fs = [freq(self.note(dd, octave)) for dd in degs]
            self.mix.add(pad(fs, length * self.bar + 0.4, bright), bar0 * self.bar, gain, 0.0)

    def drums(self, pattern, bars, gain=0.5, jingle=0.0, fill=True, boom_every=0):
        pat = RITMO[pattern]
        for b in bars:
            for i, ch in enumerate(pat):
                at = b * self.bar + i * self.step
                swing = self.step * 0.06 if i % 2 else 0
                if ch == "D":
                    self.mix.add(doum(), at + swing, gain * 1.0, 0.0)
                elif ch == "T":
                    self.mix.add(tek(seed=i), at + swing, gain * 0.55, 0.15)
                elif ch == "k":
                    self.mix.add(tek(0.08, seed=i + 7), at + swing, gain * 0.25, -0.2)
                if jingle and i % 2 == 0:
                    self.mix.add(riq(seed=i), at + swing, gain * jingle * (1.0 if i % 4 == 0 else 0.6), 0.3)
            if fill and b % 4 == 3:
                for i in range(12, 16):
                    self.mix.add(tek(0.07, seed=40 + i), b * self.bar + i * self.step, gain * 0.35, 0.1)
            if boom_every and b % boom_every == 0:
                self.mix.add(boom(), b * self.bar, gain * 0.9, 0.0)

    def bass(self, bars, pattern=(0, 6, 8, 12), degs=(0,), gain=0.35, octave=-2):
        for b in bars:
            d = degs[b % len(degs)]
            for s in pattern:
                self.mix.add(pluck(freq(self.note(d, octave)), 0.5, bright=0.6, nasal=0.6, decay=3.5),
                             b * self.bar + s * self.step, gain, 0.0)

    def arpeggio(self, bars, degs=(0, 2, 4, 7), octave=0, gain=0.22, every=2, inst="qanun"):
        for b in bars:
            for i in range(0, 16, every):
                d = degs[(i // every) % len(degs)]
                bright = 1.6 if inst == "qanun" else 1.0
                self.mix.add(pluck(freq(self.note(d, octave)), 0.45, bright=bright, decay=3.5), b * self.bar + i * self.step, gain, 0.35)

    def save(self, folder, wet=0.28, quality=2):
        self.mix.reverb(wet=wet, decay=1.8, loop=self.loop)
        self.mix.master()
        path = os.path.join(folder, self.name + ".ogg")
        write_ogg(self.mix.buf, path, quality)
        return path


def cadence(song, bar0, inst, octave=0, gain=0.5, end=0):
    """Último compasso: desce até a tônica (fecha o loop)."""
    notes = [(0, 4, end + 3), (4, 4, end + 2), (8, 2, end + 1), (10, 6, end)]
    song.play_melody(notes, bar0, inst, octave, gain)


def form(song, inst_a, inst_b, octave=0, gain=0.5, start_bar=0, sections="AABA", span_a=(-1, 5), span_b=(2, 8)):
    """Monta a melodia em seções de 4 compassos: A = motivo e variação, B = região aguda."""
    a1 = song.motif(32, 0, span_a)
    a2 = song.motif(16, 2, span_a)
    b1 = song.motif(32, 4, span_b)
    b2 = song.motif(16, 4, span_b)
    bar = start_bar
    for s in sections:
        if s == "A":
            song.play_melody(a1, bar, inst_a, octave, gain)
            song.play_melody(a2, bar + 2, inst_a, octave, gain)
            cadence(song, bar + 3, inst_a, octave, gain)
        else:
            song.play_melody(b1, bar, inst_b, octave, gain * 0.9)
            song.play_melody(b2, bar + 2, inst_b, octave, gain * 0.9)
            cadence(song, bar + 3, inst_b, octave, gain * 0.9, end=4)
        bar += 4


def titulo(out):
    s = Song("titulo", "hijaz", 62, 72, 16, seed=11)
    s.drone(gain=0.10)
    s.pads([(0, 4, [0, 2, 4]), (4, 4, [3, 5, 7]), (8, 4, [-1, 1, 4]), (12, 4, [0, 2, 4])], octave=0, gain=0.12)
    form(s, "ney", "oud", octave=0, gain=0.55, sections="ABAA")
    s.arpeggio(range(4, 16), degs=(0, 4, 7, 4), octave=0, gain=0.12, every=4)
    s.drums("leve", range(8, 16), gain=0.35, fill=False)
    return s.save(out, wet=0.38)


def cidade(out, name, maqam, tonic, bpm, seed, ritmo, lead, second, jingle=0.4):
    s = Song(name, maqam, tonic, bpm, 16, seed)
    s.drone(gain=0.07)
    form(s, lead, second, octave=0, gain=0.5, sections="AABA")
    s.bass(range(16), degs=(0, 0, 3, 4), gain=0.30)
    s.drums(ritmo, range(16), gain=0.42, jingle=jingle)
    return s.save(out, wet=0.24)


def campo(out, name, maqam, tonic, bpm, seed, lead, second, ritmo="leve", pads=True):
    s = Song(name, maqam, tonic, bpm, 16, seed)
    s.drone(gain=0.11)
    if pads:
        s.pads([(0, 8, [0, 4]), (8, 4, [3, 5]), (12, 4, [0, 4])], octave=-1, gain=0.12, bright=0.35)
    form(s, lead, second, octave=0, gain=0.48, sections="ABAB")
    s.drums(ritmo, range(0, 16), gain=0.33, fill=False)
    return s.save(out, wet=0.34)


def interior(out):
    s = Song("interior", "bayati", 62, 66, 12, seed=31)
    s.drone(gain=0.05, fifth=False)
    form(s, "oud", "oud", octave=0, gain=0.5, sections="ABA")
    s.bass(range(12), pattern=(0, 8), degs=(0, 3, 4, 0), gain=0.22)
    return s.save(out, wet=0.3)


def masmorra(out):
    s = Song("masmorra", "saba", 57, 64, 16, seed=41)
    s.drone(d=0, octave=-2, gain=0.16)
    s.pads([(0, 4, [0, 3]), (4, 4, [1, 3]), (8, 4, [0, 2]), (12, 4, [-1, 1])], octave=-1, gain=0.14, bright=0.25)
    sparse = [s.motif(32, 0, (-2, 4), rest=0.45) for _ in range(4)]
    for i, m in enumerate(sparse):
        s.play_melody(m, i * 4 + 1, "ney", 0, 0.38)
    s.drums("batida", range(16), gain=0.3, fill=False, boom_every=4)
    return s.save(out, wet=0.5)


def chefe(out):
    s = Song("chefe", "hijaz", 52, 148, 16, seed=51)
    s.drone(octave=-1, gain=0.10)
    # Ostinato em semicolcheias nas cordas graves.
    osc = [0, 0, 1, 0, 2, 0, 1, 0, 3, 2, 1, 0, 1, 2, 1, -1]
    for b in range(16):
        shift = [0, 0, 3, 4][(b // 2) % 4]
        for i, d in enumerate(osc):
            s.mix.add(pluck(freq(s.note(d + shift, -1)), 0.22, bright=0.9, nasal=1.2, decay=6), b * s.bar + i * s.step, 0.26, -0.15)
    form(s, "qanun", "ney", octave=1, gain=0.42, sections="AABB", span_a=(-2, 4), span_b=(1, 6))
    s.pads([(b, 2, [0, 4] if b % 8 < 4 else [3, 7]) for b in range(0, 16, 2)], octave=0, gain=0.12, bright=0.6)
    s.drums("ayoub", range(16), gain=0.55, jingle=0.5, boom_every=2)
    return s.save(out, wet=0.22)


def final(out):
    s = Song("final", "rast", 60, 70, 16, seed=61)
    s.drone(gain=0.08)
    s.pads([(0, 4, [0, 2, 4]), (4, 4, [3, 5, 7]), (8, 4, [4, 6, 8]), (12, 4, [0, 2, 4])], octave=0, gain=0.14)
    form(s, "ney", "qanun", octave=0, gain=0.5, sections="ABAA")
    s.arpeggio(range(16), degs=(0, 2, 4, 7), octave=-1, gain=0.12, every=2, inst="oud")
    s.drums("leve", range(4, 16), gain=0.3, fill=False)
    return s.save(out, wet=0.36)


# ---------- vinhetas curtas (sem loop) ----------

def vinheta(out, name, maqam, tonic, bpm, notes, inst="qanun", hits=(), roll=False, wet=0.35, pad_degs=None):
    s = Song(name, maqam, tonic, bpm, 2, seed=1, loop=False)
    s.play_melody(notes, 0, inst, 0, 0.6, ornament=False)
    if pad_degs:
        s.pads([(0, 2, pad_degs)], octave=0, gain=0.18)
    for pos, kind in hits:
        at = pos * s.step
        s.mix.add({"D": doum(), "T": tek(), "B": boom()}[kind], at, 0.6, 0, wrap=False)
    if roll:
        for i in range(8):
            s.mix.add(riq(seed=i), i * s.step * 0.5, 0.25, 0.2, wrap=False)
    return s.save(out, wet=wet)


def vinhetas(out):
    paths = []
    paths.append(vinheta(out, "nivel", "rast", 67, 150, [(0, 1, 0), (1, 1, 2), (2, 1, 4), (3, 2, 7), (5, 1, 4), (6, 4, 7)],
                         hits=[(0, "D"), (3, "T"), (6, "D")], roll=True, pad_degs=[0, 2, 4]))
    paths.append(vinheta(out, "missao", "hijaz", 62, 120, [(0, 2, 0), (2, 2, 4), (4, 2, 5), (6, 2, 4), (8, 8, 7)],
                         hits=[(0, "D"), (4, "T"), (8, "D")], roll=True, pad_degs=[0, 4, 7]))
    paths.append(vinheta(out, "falhou", "kurd", 62, 90, [(0, 3, 4), (3, 3, 3), (6, 3, 1), (9, 8, 0)], inst="ney",
                         hits=[(9, "D")]))
    paths.append(vinheta(out, "derrota", "saba", 57, 70, [(0, 4, 4), (4, 4, 2), (8, 4, 1), (12, 12, 0)], inst="ney",
                         hits=[(0, "B")], wet=0.5))
    paths.append(vinheta(out, "chefe_vencido", "hijaz", 62, 132,
                         [(0, 1, 0), (1, 1, 1), (2, 1, 2), (3, 1, 3), (4, 2, 4), (6, 2, 3), (8, 2, 4), (10, 10, 7)],
                         hits=[(0, "B"), (4, "D"), (8, "D"), (10, "D")], roll=True, pad_degs=[0, 4, 7]))
    paths.append(vinheta(out, "capitulo", "hijaz", 62, 80, [(0, 6, 0), (6, 2, 1), (8, 8, 4)], inst="ney",
                         hits=[(0, "B"), (8, "D")], wet=0.5, pad_degs=[0, 4]))
    return paths


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    only = set(sys.argv[2:])
    jobs = {
        "titulo": lambda: titulo(out),
        "cidade_deserto": lambda: cidade(out, "cidade_deserto", "hijaz", 62, 104, 21, "maqsum", "oud", "ney"),
        "cidade_costa": lambda: cidade(out, "cidade_costa", "nahawand", 67, 96, 22, "baladi", "qanun", "ney", 0.55),
        "cidade_norte": lambda: cidade(out, "cidade_norte", "rast", 60, 92, 23, "masmudi", "oud", "qanun", 0.3),
        "campo_deserto": lambda: campo(out, "campo_deserto", "hijaz", 62, 84, 24, "ney", "oud"),
        "campo_costa": lambda: campo(out, "campo_costa", "kurd", 64, 88, 25, "qanun", "ney"),
        "campo_norte": lambda: campo(out, "campo_norte", "nahawand", 60, 80, 26, "oud", "ney", ritmo="batida"),
        "interior": lambda: interior(out),
        "masmorra": lambda: masmorra(out),
        "chefe": lambda: chefe(out),
        "final": lambda: final(out),
        "vinhetas": lambda: vinhetas(out),
    }
    for name, job in jobs.items():
        if only and name not in only:
            continue
        print(name, job())


if __name__ == "__main__":
    main()
