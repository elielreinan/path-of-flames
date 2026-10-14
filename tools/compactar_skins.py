"""Compacta as folhas de skin (13x44 quadros de 96x64) do fio de Artes para o jogo.

Guarda só as animações que NPCs, aliados e inimigos humanos usam e corta cada quadro
para 48x40 em volta do pé. Saída: assets/personagens/{npcs,inimigos}/<id>.png.
Uso: python3 tools/compactar_skins.py ../arte/npcs
"""
import os
import sys

from PIL import Image

# Mesma ordem de SkinSprite.ANIMS (linha original de cada animação).
ANIMS = ["parado", "andar", "golpe", "dano", "morrer", "nadar"]
LINHA = {"parado": 0, "andar": 4, "golpe": 12, "dano": 16, "morrer": 20, "nadar": 24}
COLS, FW, FH = 13, 96, 64
CORTE = (24, 14, 72, 54)  # 48x40; o pé (48,40) vira (24,26)
CW, CH = CORTE[2] - CORTE[0], CORTE[3] - CORTE[1]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def compactar(src, dst):
    im = Image.open(src).convert("RGBA")
    out = Image.new("RGBA", (COLS * CW, len(ANIMS) * 4 * CH))
    for i, nome in enumerate(ANIMS):
        for d in range(4):
            linha = LINHA[nome] + d
            for c in range(COLS):
                x, y = c * FW, linha * FH
                q = im.crop((x + CORTE[0], y + CORTE[1], x + CORTE[2], y + CORTE[3]))
                out.paste(q, (c * CW, (i * 4 + d) * CH))
    out.save(dst, optimize=True)
    # Retrato do diálogo (rosto e tronco, olhando para a frente) em arquivo pequeno à parte.
    retratos = os.path.join(os.path.dirname(os.path.dirname(dst)), "retratos")
    os.makedirs(retratos, exist_ok=True)
    im.crop((36, 18, 60, 42)).save(os.path.join(retratos, os.path.basename(dst)), optimize=True)


def main():
    arte = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "..", "arte", "npcs")
    total = 0
    for pasta in ("npcs", "inimigos"):
        destino = os.path.join(ROOT, "assets", "personagens", pasta)
        os.makedirs(destino, exist_ok=True)
        for f in sorted(os.listdir(os.path.join(arte, pasta))):
            if f.endswith(".png"):
                compactar(os.path.join(arte, pasta, f), os.path.join(destino, f))
                total += 1
    print("skins compactadas:", total)


if __name__ == "__main__":
    main()
