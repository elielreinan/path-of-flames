"""Sintetizador simples (numpy) para as músicas e efeitos do Chamado das Brasas.

Tudo aqui é gerado por código, sem amostras de terceiros: o resultado é obra
original do projeto, liberada como CC0.
"""
import subprocess
import numpy as np

SR = 32000


def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def fft_filter(x, low=None, high=None):
    """Passa-baixa/passa-alta suaves no domínio da frequência."""
    n = len(x)
    if n == 0:
        return x
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / SR)
    gain = np.ones_like(f)
    if low:
        gain *= 1 / np.sqrt(1 + (f / low) ** 4)
    if high:
        gain *= 1 / np.sqrt(1 + (high / np.maximum(f, 1e-3)) ** 4)
    return np.fft.irfft(spec * gain, n)


def env(n, a=0.005, r=0.05, dur=None):
    e = np.ones(n)
    na = max(1, int(a * SR))
    nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    if nr < n:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


# ---------- instrumentos ----------

def pluck(f, dur, bright=1.0, nasal=1.0, decay=2.2):
    """Corda dedilhada (alaúde/oud ou qanun): harmônicos que somem em ritmos diferentes."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    rng = np.random.default_rng(int(f * 7))
    for k in range(1, 16):
        fk = f * k * (1 + 0.0007 * k * k)
        if fk > SR / 2.2:
            break
        amp = (1.0 / k ** (1.25 / bright)) * abs(np.sin(np.pi * k * 0.18)) * 1.6
        if 2 <= k <= 4:
            amp *= nasal
        d = decay + 1.6 * k / bright
        out += amp * np.sin(2 * np.pi * fk * t + rng.uniform(0, 6.28)) * np.exp(-d * t)
    click = rng.standard_normal(min(len(t), 160)) * np.exp(-np.arange(min(len(t), 160)) / 30)
    out[: len(click)] += click * 0.06 * bright
    return out * env(len(t), 0.002, 0.03)


def ney(f, dur, vib=0.006, breath=0.035):
    """Flauta de bambu (ney): sopro, vibrato que entra devagar."""
    t = t_axis(dur)
    vib_env = np.clip((t - 0.18) / 0.3, 0, 1)
    phase = 2 * np.pi * np.cumsum(f * (1 + vib * vib_env * np.sin(2 * np.pi * 5.2 * t))) / SR
    tone = np.sin(phase) + 0.28 * np.sin(2 * phase) + 0.12 * np.sin(3 * phase) + 0.04 * np.sin(4 * phase)
    noise = fft_filter(fft_filter(np.random.default_rng(int(f)).standard_normal(len(t)), low=f * 2.5, high=f * 0.9), low=f * 2.5, high=f * 0.9)
    out = tone + breath * noise / (np.std(noise) + 1e-9)
    a = min(0.09, dur * 0.3)
    e = env(len(t), a, min(0.12, dur * 0.3))
    return out * e * 0.6


def drone(f, dur, bright=0.5):
    """Bordão contínuo: dois osciladores levemente desafinados com muitos harmônicos."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for det in (-0.12, 0.0, 0.13):
        for k in range(1, 14):
            fk = f * k + det * k
            if fk > 5000:
                break
            out += (1 / k) * np.exp(-k * (1 - bright) * 0.35) * np.sin(2 * np.pi * fk * t + k)
    lfo = 0.8 + 0.2 * np.sin(2 * np.pi * 0.13 * t)
    return out * lfo / 3.0


def pad(freqs, dur, bright=0.5):
    """Cordas suaves (acorde sustentado)."""
    t = t_axis(dur)
    out = np.zeros_like(t)
    for f in freqs:
        for det in (-0.25, 0.25):
            for k in range(1, 10):
                fk = (f + det) * k
                if fk > 6000:
                    break
                out += (1 / k ** 1.4) * np.exp(-k * (1 - bright) * 0.3) * np.sin(2 * np.pi * fk * t + k * 1.7 + det)
    e = env(len(t), min(0.35, dur * 0.3), min(0.4, dur * 0.3))
    return out * e / (len(freqs) * 2.0)


def doum(dur=0.45, f0=150, f1=62):
    t = t_axis(dur)
    pitch = f1 + (f0 - f1) * np.exp(-t * 28)
    ph = 2 * np.pi * np.cumsum(pitch) / SR
    out = np.sin(ph) * np.exp(-t * 7.5)
    n = np.random.default_rng(1).standard_normal(len(t)) * np.exp(-t * 90) * 0.3
    return out + fft_filter(n, low=1800)


def tek(dur=0.12, seed=2):
    t = t_axis(dur)
    n = np.random.default_rng(seed).standard_normal(len(t))
    n = fft_filter(n, low=4200, high=1500) * np.exp(-t * 60)
    ring = np.sin(2 * np.pi * 760 * t) * np.exp(-t * 45) * 0.6
    return (n * 0.55 + ring) * 0.6


def riq(dur=0.16, seed=3):
    t = t_axis(dur)
    n = np.random.default_rng(seed).standard_normal(len(t))
    n = fft_filter(n, low=9000, high=5000) * np.exp(-t * 30)
    return n * 0.2


def boom(dur=1.2, f=48):
    t = t_axis(dur)
    pitch = f + 40 * np.exp(-t * 12)
    ph = 2 * np.pi * np.cumsum(pitch) / SR
    out = np.sin(ph) * np.exp(-t * 3.2)
    n = fft_filter(np.random.default_rng(4).standard_normal(len(t)), low=600) * np.exp(-t * 18) * 0.5
    return (out + n) * 1.2


# ---------- mixagem ----------

class Mix:
    def __init__(self, seconds):
        self.n = int(round(seconds * SR))
        self.buf = np.zeros((2, self.n))

    def add(self, sound, at, gain=1.0, pan=0.0, wrap=True):
        start = int(round(at * SR))
        l = gain * np.cos((pan + 1) * np.pi / 4) * 1.414
        r = gain * np.sin((pan + 1) * np.pi / 4) * 1.414
        idx = (np.arange(len(sound)) + start)
        if wrap:
            idx %= self.n
        else:
            keep = idx < self.n
            idx, sound = idx[keep], sound[keep]
        np.add.at(self.buf[0], idx, sound * l)
        np.add.at(self.buf[1], idx, sound * r)

    def reverb(self, wet=0.25, decay=1.6, loop=True):
        """Reverberação por convolução com ruído que decai; circular para o loop fechar."""
        rng = np.random.default_rng(9)
        ir_n = int(decay * SR)
        t = np.arange(ir_n) / SR
        n = self.n if loop else self.n + ir_n
        out = np.zeros((2, n))
        for ch in range(2):
            ir = rng.standard_normal(ir_n) * np.exp(-t * 6.9 / decay)
            ir = fft_filter(ir, low=4500)
            ir[: int(0.012 * SR)] = 0
            ir /= np.sqrt(np.sum(ir ** 2))
            x = np.zeros(n)
            x[: self.n] = self.buf[ch]
            if loop:
                ir = np.concatenate([ir, np.zeros(max(0, n - ir_n))])[:n] if ir_n <= n else ir[:n]
            y = np.fft.irfft(np.fft.rfft(x, n) * np.fft.rfft(ir, n), n)
            out[ch] = x + wet * y
        self.buf = out
        self.n = self.buf.shape[1]

    def master(self, rms_db=-17.0, peak=0.95):
        """Iguala o volume entre as faixas (RMS) com um limitador suave nos picos."""
        x = self.buf
        rms = np.sqrt(np.mean(x ** 2)) + 1e-9
        x = x * (10 ** (rms_db / 20) / rms)
        x = np.tanh(x / peak) * peak
        self.buf = x


def write_ogg(buf, path, quality=2, mono=False):
    data = buf.mean(axis=0, keepdims=True) if mono else buf
    pcm = (np.clip(data.T, -1, 1) * 32767).astype("<i2").tobytes()
    ch = data.shape[0]
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", str(ch), "-i", "-",
         "-c:a", "libvorbis", "-q:a", str(quality), path],
        input=pcm, check=True)
