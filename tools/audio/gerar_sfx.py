"""Gera os efeitos sonoros do Chamado das Brasas por síntese (obra original, CC0).

Uso: python3 gerar_sfx.py <pasta_saida>
"""
import os
import sys
import numpy as np
from sintese import SR, t_axis, fft_filter, write_ogg, pluck, doum, tek, boom, freq

rng = np.random.default_rng(77)


def noise(dur):
    return rng.standard_normal(int(dur * SR))


def sweep_noise(dur, f0, f1, q=0.35):
    """Ruído com um filtro que varre de f0 a f1 (feito em fatias)."""
    n = int(dur * SR)
    out = np.zeros(n)
    x = noise(dur + 0.05)
    hop = 256
    for i in range(0, n, hop):
        f = f0 * (f1 / f0) ** (i / n)
        seg = x[i:i + hop * 4]
        y = fft_filter(seg, low=f * (1 + q), high=f * (1 - q * 0.8))
        out[i:i + hop] += y[:min(hop, n - i)]
    return out


def tone_sweep(dur, f0, f1, shape="sine"):
    t = t_axis(dur)
    f = f0 * (f1 / f0) ** (t / dur)
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "square":
        return np.sign(np.sin(ph)) * 0.5
    if shape == "saw":
        return 2 * ((ph / (2 * np.pi)) % 1) - 1
    return np.sin(ph)


def decay(n, rate):
    return np.exp(-np.arange(n) / SR * rate)


def fade(x, a=0.003, r=0.02):
    n = len(x)
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    x = x.copy()
    x[:na] *= np.linspace(0, 1, na)
    x[-nr:] *= np.linspace(1, 0, nr)
    return x


def norm(x, peak=0.9):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def pad_to(x, n):
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:n]


def mix(*parts):
    n = max(len(p) for p in parts)
    return sum(pad_to(p, n) for p in parts)


def swing(seed_shift=0):
    """Espada cortando o ar."""
    d = 0.22
    t = t_axis(d)
    env = np.sin(np.pi * np.clip(t / d, 0, 1)) ** 2
    return fade(norm(sweep_noise(d, 900 + seed_shift * 120, 3800, 0.5) * env, 0.75))


def hit():
    """Golpe acertando (pancada + estalo)."""
    body = tone_sweep(0.16, 220, 70) * decay(int(0.16 * SR), 22)
    crack = fft_filter(noise(0.08), low=6000, high=900) * decay(int(0.08 * SR), 60)
    return fade(norm(mix(body, crack * 0.8), 0.9))


def hit_metal():
    """Golpe no escudo do chefe."""
    t = t_axis(0.5)
    ring = sum(np.sin(2 * np.pi * f * t) / (i + 1) for i, f in enumerate([880, 1320, 2093, 2960])) * decay(len(t), 9)
    click = fft_filter(noise(0.03), high=2000)
    return fade(norm(mix(ring, click), 0.75))


def fireball():
    """Bola de fogo saindo: sopro + chiado de chama."""
    d = 0.42
    t = t_axis(d)
    whoosh = sweep_noise(d, 300, 1400, 0.6) * np.sin(np.pi * np.clip(t / d, 0, 1))
    crackle = np.zeros(len(t))
    for _ in range(18):
        at = rng.integers(0, len(t) - 400)
        crackle[at:at + 400] += fft_filter(noise(400 / SR), high=2500) * decay(400, 300)
    roar = tone_sweep(d, 90, 140, "saw") * 0.12 * np.sin(np.pi * np.clip(t / d, 0, 1))
    return fade(norm(mix(whoosh, crackle * 0.35, fft_filter(roar, low=600)), 0.8))


def fire_burst():
    """Bola de fogo explodindo no alvo."""
    d = 0.5
    b = fft_filter(noise(d), low=1800) * decay(int(d * SR), 9)
    thump = tone_sweep(0.25, 120, 45) * decay(int(0.25 * SR), 14)
    return fade(norm(mix(b, thump * 0.9), 0.85))


def fury():
    """Fúria das Brasas: giro em chamas."""
    d = 1.1
    t = t_axis(d)
    swirl = sweep_noise(d, 250, 2500, 0.5) * (0.6 + 0.4 * np.sin(2 * np.pi * 7 * t)) * np.sin(np.pi * np.clip(t / d, 0, 1))
    return fade(norm(mix(swirl, boom(1.1, 44) * 0.8), 0.9), r=0.15)


def hurt():
    """Ifrit levou dano."""
    d = 0.28
    body = tone_sweep(d, 340, 140, "saw") * decay(int(d * SR), 12)
    body = fft_filter(body, low=1600)
    thud = tone_sweep(0.12, 160, 60) * decay(int(0.12 * SR), 30)
    return fade(norm(mix(body * 0.7, thud), 0.85))


def enemy_hurt():
    d = 0.18
    s = tone_sweep(d, 520, 260, "square") * decay(int(d * SR), 18)
    return fade(norm(fft_filter(s, low=2500), 0.6))


def enemy_die():
    d = 0.45
    s = tone_sweep(d, 600, 90, "square") * decay(int(d * SR), 7)
    puff = fft_filter(noise(0.3), low=2200) * decay(int(0.3 * SR), 14)
    return fade(norm(mix(fft_filter(s, low=2200) * 0.6, puff), 0.75))


def step(seed):
    """Passo na areia: ruído grave e curtinho."""
    r = np.random.default_rng(seed)
    d = 0.09
    n = fft_filter(r.standard_normal(int(d * SR)), low=1400 + seed * 80, high=200) * decay(int(d * SR), 45)
    return fade(norm(n, 0.5), a=0.004)


def swim():
    d = 0.35
    t = t_axis(d)
    s = sweep_noise(d, 600, 300, 0.6) * np.sin(np.pi * np.clip(t / d, 0, 1))
    bub = sum(np.sin(2 * np.pi * (500 + 300 * k) * t * (1 + t * 3)) * decay(len(t), 25) * (t > 0.05 * k) for k in range(3))
    return fade(norm(mix(s, bub * 0.15), 0.5))


def pickup():
    """Pegou item: dois tons subindo (qanun)."""
    a = pluck(freq(79), 0.4, bright=1.6, decay=4)
    b = pluck(freq(86), 0.5, bright=1.6, decay=4)
    return fade(norm(mix(a, np.concatenate([np.zeros(int(0.07 * SR)), b])), 0.7))


def coin():
    t = t_axis(0.35)
    a = np.sin(2 * np.pi * 1975 * t) * decay(len(t), 14) * (t < 0.07)
    b = np.sin(2 * np.pi * 2637 * t) * decay(len(t), 10) * (t >= 0.07)
    return fade(norm(a + b, 0.55))


def potion():
    """Bebeu poção: borbulhas subindo."""
    d = 0.6
    out = np.zeros(int(d * SR))
    for k in range(9):
        at = int(k * 0.06 * SR)
        bd = 0.08
        f0 = 400 + k * 90
        bub = tone_sweep(bd, f0, f0 * 2.2) * decay(int(bd * SR), 30)
        out[at:at + len(bub)] += bub
    chime = pluck(freq(84), 0.5, bright=1.5, decay=3)
    return fade(norm(mix(out * 0.6, np.concatenate([np.zeros(int(0.4 * SR)), chime * 0.6])), 0.7))


def chest():
    """Baú abrindo: rangido + brilho."""
    d = 0.4
    t = t_axis(d)
    creak = fft_filter(tone_sweep(d, 180, 260, "saw") * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * t)), low=1800) * 0.4
    sparkle = sum(pluck(freq(m), 0.5, bright=1.8, decay=4) for m in [84])
    out = mix(creak, np.concatenate([np.zeros(int(0.32 * SR)), sparkle]))
    for i, m in enumerate([88, 91, 96]):
        out = mix(out, np.concatenate([np.zeros(int((0.4 + 0.07 * i) * SR)), pluck(freq(m), 0.5, bright=1.8, decay=4) * 0.7]))
    return fade(norm(out, 0.7))


def door():
    """Porta / entrada de mapa: passos rápidos + batente."""
    thud = tone_sweep(0.2, 110, 60) * decay(int(0.2 * SR), 18)
    creak = fft_filter(tone_sweep(0.25, 300, 200, "saw"), low=1500) * decay(int(0.25 * SR), 6) * 0.25
    return fade(norm(mix(creak, np.concatenate([np.zeros(int(0.18 * SR)), thud])), 0.6))


def mount():
    """Montaria: relincho/grunhido curto + trote."""
    d = 0.35
    t = t_axis(d)
    g = fft_filter(tone_sweep(d, 260, 180, "saw") * (0.6 + 0.4 * np.sin(2 * np.pi * 22 * t)), low=1400) * decay(len(t), 5)
    trot = mix(*[np.concatenate([np.zeros(int(k * 0.11 * SR)), step(k + 3) * 0.8]) for k in range(4)])
    return fade(norm(mix(g * 0.6, trot), 0.6))


def boss_roar():
    d = 1.4
    t = t_axis(d)
    base = tone_sweep(d, 95, 60, "saw") * (0.7 + 0.3 * np.sin(2 * np.pi * 31 * t))
    growl = fft_filter(base, low=900) + fft_filter(noise(d), low=700) * 0.4
    e = np.clip(t / 0.25, 0, 1) * np.exp(-np.clip(t - 0.4, 0, None) * 2.5)
    return fade(norm(growl * e, 0.9), r=0.2)


def boss_slam():
    return fade(norm(mix(boom(0.9, 40), fft_filter(noise(0.4), low=1200) * decay(int(0.4 * SR), 10) * 0.6), 0.9))


def boss_phase():
    """Chefe mudou de fase."""
    d = 0.9
    s = tone_sweep(d, 80, 320, "saw")
    s = fft_filter(s, low=1500) * np.sin(np.pi * np.clip(t_axis(d) / d, 0, 1))
    return fade(norm(mix(s, boom(0.9, 50) * 0.7), 0.85))


def heal():
    out = np.zeros(int(0.7 * SR))
    for i, m in enumerate([72, 76, 79, 84]):
        p = pluck(freq(m), 0.5, bright=1.5, decay=3.5)
        at = int(i * 0.08 * SR)
        out[at:at + len(p)] += p[: len(out) - at]
    return fade(norm(out, 0.6))


def blip():
    """Letra do diálogo (bem baixinho)."""
    t = t_axis(0.03)
    return fade(np.sin(2 * np.pi * 620 * t) * decay(len(t), 80) * 0.35, a=0.001, r=0.01)


def sleep():
    out = np.zeros(int(1.6 * SR))
    for i, m in enumerate([79, 76, 72, 67]):
        p = pluck(freq(m), 0.9, bright=0.9, decay=2)
        at = int(i * 0.3 * SR)
        out[at:at + len(p)] += p[: len(out) - at]
    return fade(norm(out, 0.55), r=0.2)


def push():
    """Pedra sendo empurrada."""
    d = 0.4
    s = fft_filter(noise(d), low=500, high=60) * (0.6 + 0.4 * np.sin(2 * np.pi * 17 * t_axis(d)))
    return fade(norm(s, 0.6), a=0.03, r=0.08)


def buy():
    return fade(norm(mix(coin(), np.concatenate([np.zeros(int(0.09 * SR)), coin() * 0.8])), 0.6))


SOUNDS = {
    "espada_1": lambda: swing(0), "espada_2": lambda: swing(2), "espada_3": lambda: swing(4),
    "acerto": hit, "acerto_metal": hit_metal,
    "fogo": fireball, "fogo_explode": fire_burst, "furia": fury,
    "dano": hurt, "inimigo_dano": enemy_hurt, "inimigo_morre": enemy_die,
    "passo_1": lambda: step(1), "passo_2": lambda: step(2), "passo_3": lambda: step(3), "passo_4": lambda: step(4),
    "nadar": swim, "pegar": pickup, "moeda": coin, "pocao": potion, "cura": heal, "bau": chest,
    "porta": door, "montar": mount, "chefe_rugido": boss_roar, "chefe_impacto": boss_slam,
    "chefe_fase": boss_phase, "letra": blip, "dormir": sleep, "empurrar": push, "comprar": buy,
}


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for name, fn in SOUNDS.items():
        x = fn()
        write_ogg(np.stack([x, x]), os.path.join(out, name + ".ogg"), quality=3, mono=True)
        print(name, round(len(x) / SR, 2))


if __name__ == "__main__":
    main()
