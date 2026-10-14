# Sons e músicas do Path of Flames: origem e licenças

Tudo aqui pode ser usado em projeto comercial, sem pagar nada e sem pedir permissão.

## Músicas e efeitos próprios (CC0)
- `musica/*.ogg` (11 trilhas em loop e 6 vinhetas) e `sfx/*.ogg` (menos `quebrar.ogg`).
- Compostos e gerados por código para este jogo, sem nenhuma amostra de terceiros:
  `tools/audio/compor_musica.py` (maqams hijaz, bayati, rast, nahawand, kurd e saba;
  alaúde, qanun, ney, darbuka e riq sintetizados) e `tools/audio/gerar_sfx.py`.
- Licença: CC0 1.0 (domínio público), https://creativecommons.org/publicdomain/zero/1.0/
- Para refazer: `cd tools/audio && python3 compor_musica.py ../../assets/audio/musica`
  e `python3 gerar_sfx.py ../../assets/audio/sfx` (precisa de numpy e ffmpeg).

## Sons de interface: Kenney (CC0)
- `ui/toque.ogg` (click_002), `ui/abrir.ogg` (open_002), `ui/fechar.ogg` (close_002),
  `ui/confirmar.ogg` (confirmation_002), `ui/erro.ogg` (error_006), `ui/soltar.ogg` (drop_002),
  `ui/selecionar.ogg` (select_002): pacote **Interface Sounds** de Kenney (www.kenney.nl),
  cópia em https://github.com/Calinou/kenney-interface-sounds
- `sfx/quebrar.ogg` (break.ogg): **Starter Kit 3D Platformer** de Kenney,
  https://github.com/KenneyNL/Starter-Kit-3D-Platformer (sons CC0)
- Licença: CC0 1.0. Crédito não é obrigatório, mas o jogo credita Kenney nos créditos.
  Texto original da licença em `KENNEY_LICENSE.txt`.
- Convertidos de WAV para OGG mono (32 kHz) para deixar o APK leve.
