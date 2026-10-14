# Path of Flames: modo história offline (Godot 4.3 ou mais novo)

Ifrit sai da casa da mãe, Samira, em Areia Rubra, para descobrir o que aconteceu com o pai, Kadir, e salvar as 7 Chamas Sagradas de Zahra. O roteiro completo está em `../roteiro.md`.

## O que tem
- **7 capítulos e 7 cidades** distantes umas das outras: Areia Rubra, Oásis de Miraj, Porto Coral, Vale dos Ventos, Ruínas de Qadim, Cidadela de Sal e Trono Cinzento.
- **22 mapas** (cidades, estradas, covis, navio, fábrica, biblioteca, quartel, trono).
- **80 NPCs** com 190 diálogos que mudam conforme o progresso, com escolhas de resposta.
- **45 missões**: 27 principais e 18 secundárias, do nível 1 ao 22, com diário de missões.
- **24 cutscenes**: títulos de capítulo, personagens andando, tremor de tela e transições.
- **7 chefes** com padrões de ataque (investida, invocar, projéteis) e fúria com metade da vida.
- **4 aliados** (Nadia, Bako, Omar e Kadir) que seguem o Ifrit e atacam por conta própria.
- **Inventário** com poções, comida, armas equipáveis, materiais e itens de missão.
- **Lojas** que vendem só na moeda local, e **câmbio** com um cambista em cada cidade (taxa de 10%).
- Moedas: Brasas (valor 1), Pérolas (3) e Coroas (5).
- Nível e XP, salvamento automático ao trocar de mapa, e perda de 10% da moeda local ao cair.

## Controles
| Ação | Celular | PC |
|---|---|---|
| Andar | joystick | WASD ou setas |
| Golpe de espada | GOLPE | Espaço ou J |
| Bola de fogo (depois do Pergaminho da Chama) | FOGO | K |
| Falar, abrir baú, ler placa | FALAR | E, L ou Enter |
| Inventário | ícone da bolsa | I |
| Diário de missões | ícone do pergaminho | Q |
| Pausa e menu (bolsa, missões, mapa, configurações, salvar) | ícone de pausa ou botão "voltar" | Esc ou P |
| Mapa completo | tocar no mini mapa | pelo menu de pausa |

Tamanho do joystick e dos botões, modo do joystick (fixo ou livre), opacidade, velocidade do texto, mini mapa e volume ficam em **Pausa > Configurações**.

## Como abrir
1. Baixe o Godot (4.3 ou mais novo; testado também no 4.7) em https://godotengine.org/download
2. No Godot, clique em **Importar** e escolha o `project.godot` desta pasta.
3. Aperte **F5** para jogar. No PC o mouse simula o toque.

## Como gerar o APK para Android
O projeto já vem com o preset **Android** (`export_presets.cfg`): ícone, nome "Path of Flames", pacote `com.eliel.ifritlegend`, tela cheia e texturas ETC2/ASTC.
1. No Godot: **Editor > Gerenciar Modelos de Exportação** e baixe os modelos da sua versão.
2. Instale o Android SDK e o JDK conforme https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html e aponte os caminhos em **Editor > Configurações do Editor > Exportar > Android**.
3. **Projeto > Exportar**, escolha **Android** e clique em **Exportar Projeto**. O APK sai em `build/ifrit-legend.apk`. Com o celular no cabo, o botão de Android no topo do editor instala e roda direto.

## Estrutura
- `data/`: todo o conteúdo em JSON (itens, inimigos, missões, NPCs, lojas, moedas, `dialogos/`, `cutscenes/`, `mapas/`). Dá para editar falas e missões sem mexer no código.
- `scripts/autoload/`: `Data` (carrega o JSON) e `GameState` (flags, missões, inventário, carteira, save).
- `scripts/entities/`: jogador, inimigos, chefes, aliados, NPCs, baús, placas e projéteis.
- `scripts/ui/`: diálogo, HUD, inventário, loja, câmbio, diário de missões e tela de título.
- `scripts/world/world.gd`: carrega mapas, passagens, gatilhos, diálogos, ações e cutscenes.
- `tools/`: scripts Python que geram sprites, tiles e mapas.

## Ferramentas
- `python3 tools/construir_mapas.py` recria os mapas em `data/mapas/` a partir dos desenhos em ASCII (capítulo 1 nesse arquivo, capítulos 2 a 7 em `tools/capitulos_2_7.py`).
- `python3 tools/validar_conteudo.py` confere se diálogos, missões, itens, NPCs, mapas e cutscenes se referenciam corretamente.
- `tools/gerar_sprites.py`, `tools/gerar_tiles.py` e `tools/gerar_criaturas.py` geram a arte provisória 16x16.

## Créditos
- Arte do **Calango** (inimigo das Dunas Rubras, em tamanho original e com animação de andar): amigo do Eliel, usada com permissão. Nome do autor a confirmar.
- Os demais sprites são provisórios, gerados pelos scripts em `tools/`.
