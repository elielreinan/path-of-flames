"""Copia a interface do fio de Artes (arte/ui e arte/efeitos) para assets/ui e assets/efeitos.

Uso (na pasta game/): python3 tools/integrar_ui.py
Botões de ação e quadrados vão na versão x2 (o jogo desenha em canvas_items, então ficam nítidos);
painéis 9-slice, diálogo, título e chefes vão no tamanho nativo.
"""
import glob
import os
import shutil

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(os.path.dirname(GAME), "arte", "ui")
FX = os.path.join(os.path.dirname(GAME), "arte", "efeitos")
OUT = os.path.join(GAME, "assets", "ui")


def copiar(src, dst):
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.copy(src, dst)


n = 0
for f in glob.glob(os.path.join(UI, "x2", "botoes", "*.png")):
    nome = os.path.basename(f)
    if nome.startswith(("acao_", "quad_", "moldura_", "icone_")):
        copiar(f, os.path.join(OUT, "botoes", nome)); n += 1
for f in glob.glob(os.path.join(UI, "botoes", "menu_*.png")):
    copiar(f, os.path.join(OUT, "botoes", os.path.basename(f))); n += 1
for pasta in ("paineis", "dialogo", "chefes"):
    for f in glob.glob(os.path.join(UI, pasta, "*.png")):
        copiar(f, os.path.join(OUT, pasta, os.path.basename(f))); n += 1
for nome in ("fundo_titulo.png", "logo_x2.png"):
    copiar(os.path.join(UI, "titulo", nome), os.path.join(OUT, "titulo", nome)); n += 1
for nome in ("bola_fogo_voo.png", "bola_fogo_disparo.png", "bola_fogo_explosao.png"):
    copiar(os.path.join(FX, nome), os.path.join(GAME, "assets", "efeitos", nome)); n += 1
print("arquivos:", n)
