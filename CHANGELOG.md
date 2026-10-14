# Changelog do Path of Flames (antes Ifrit Legend / Chamado das Brasas)

## Pendências do Projeto Brasas

| # | Tarefa | Situação |
|---|---|---|
| 1 | Definir um novo nome para o projeto | Aguardando escolha do Eliel |
| 2 | Correções de bugs e falhas do projeto inicial | Em andamento: chefe duplicado, cena travando, toque duplo, save, joystick preso corrigidos |
| 3 | Concluir a história do jogo | Os 7 capítulos estão jogáveis do início ao fim; falta revisão de texto e ajuste de dificuldade |
| 4 | Mecânicas de armamentos, classes e montarias | A fazer |
| 5 | Converter o código para C++ | Aguardando escolha do caminho (só sistemas pesados, reescrita total ou manter GDScript) |
| 6 | Melhorar as telas de diálogo | Feito na 0.3.0 |
| 7 | Bug do chefe multiplicado ao entrar na sala | Corrigido na 0.3.0 |
| 8 | Posição dos botões e tamanho do joystick | Feito na 0.3.0 (ajustável nas Configurações) |
| 9 | Assets e sons do jogo | Sons e músicas livres (CC0) feitos na 0.9.5; arte esperando arquivos do Eliel |
| 10 | Pausa, mini mapa, menu e configurações | Feito na 0.3.0 |

Também pendente: mecânicas estilo Graal de `mecanicas-jogabilidade.md` (cortar arbustos, levantar e arremessar, corações, bombas, arco, escudo), personagens montados por partes (esperando arquivos de arte do Eliel) e o nome do autor do Calango nos créditos.

## Pendências da lista 2 (13/10/2026)

| Tarefa | Situação |
|---|---|
| Botão de acesso rápido configurável (poção) | Feito na 0.4.0 |
| EXP conforme a dificuldade do inimigo | Feito na 0.4.0 |
| Física: um inimigo não entra no outro | Feito na 0.4.0 |
| Física de terreno: areia, caminho, nadar na água | Feito na 0.4.0 |
| Efeito especial ao subir de nível | Feito na 0.4.0 |
| Nome e vida dos inimigos, nome dos NPCs | Feito na 0.4.0 |
| Resumir os botões da pausa | Feito na 0.4.0 |
| Dash e tempo de recarga das habilidades | Feito na 0.4.0 |
| Melhorar os drops dos inimigos | Feito na 0.5.0 |
| Efeitos de status (veneno, queimadura, lentidão...) | Feito na 0.5.0 |
| Sistema de honra por boas ações | Feito na 0.5.0 |
| Hierarquia conforme os feitos | Feito na 0.5.0 |
| Classe única (guerreiro, feiticeiro, clérigo...) | Feito na 0.5.0 |
| Nível mínimo para entrar em certos lugares | Feito na 0.5.0 |
| Entrar nas casas e conversar com moradores | Feito na 0.5.0 |
| Puzzles | A fazer (lote 3) |
| Domar feras como montaria | A fazer (lote 3) |
| Caminho do Vale dos Ventos ao Mar de Areia sem sentido | Feito na 0.6.0 |
| Mapa geral no mini mapa, revelado conforme o progresso | Feito na 0.6.0 |
| Slots de arma e armadura separados dos suprimentos | Feito na 0.6.0 |
| Inventário estilo Resident Evil | Feito na 0.6.0 |
| Manter o save atual nas atualizações | Feito: o APK instala por cima sem perder o progresso |
| Poema ao zerar o jogo | A fazer (lote 3) |

## Lista 3, "Chamado das Brasas" (13/10/2026; virou o nome do jogo na 0.9.1)

Correções (feitas na 0.7.2): textos centralizados nas telas de missão e chefe, chefe recomeça do zero ao morrer, mobs não grudam, botões voltam ao renascer, dificuldade sobe a cada chefe.

Implementações: feitas na 0.8.0.
A fazer:
- (feito) Implementações: dormir na estalagem escurece e clareia; tirar o dash; montaria; cidades mais organizadas; foco na física; caminhos sem saída viram áreas de treino, cultivo de nível e vilas extras; tela especial ao concluir ou falhar missão; efeitos melhores ao matar chefe; golpe especial; diálogos estilo Stardew Valley; segredo do Ancião Zazu; NPCs nadam; sinal de melhor ou pior ao ver equipamento; IA melhor de aliados e mobs.
- (feito na 0.9.0) História (num APK só, sem lotes): chances de o herói ser desonesto; jogo mais difícil e longo (zerou em menos de 1h); um final por aliado conforme a honra; easter eggs e referências, incluindo "Conheça a ti mesmo"; poema final estilo Minecraft; plot twist no fim abrindo continuação.

## 0.9.8 (14/10/2026) — Path of Flames
- O jogo agora se chama **Path of Flames** (título, créditos, nome do app). Pacote com.eliel.ifritlegend e pasta de save mantidos: o save continua.
- Créditos: "Ideia e direção: Eliel Reinan".
- Código no GitHub: github.com/elielreinan/path-of-flames.

## 0.9.7 (14/10/2026) — criaturas novas
- 18 bichos e chefes com folhas novas animadas (parado, andar, ataque, dano, morte; chefes com golpe especial), do fio de Artes (arte/criaturas → assets/criaturas, data/criaturas.json, scripts/entities/creature_sprite.gd). Inimigos ganharam "criatura" no inimigos.json.
- Montarias novas (camelo, hiena, lobo de metal) com animação de andar e correr; o Ifrit senta na sela ("criatura" no montarias.json).
- A arte do Calango do amigo saiu do jogo (guardada em ifrit-legend/fora_do_jogo/calango_amigo); o calango agora é um teiú dourado novo. Créditos atualizados.
- Chefes mantêm o raio 12 (com 16 a Rainha ficava fácil no nv 12); bichos pequenos raio 8.

## 0.9.6 (14/10/2026) — versão única
- Junta tudo num APK só: sons e músicas (fio de áudio) + cenário v2 + skins dos NPCs. Substitui os dois 0.9.5 (ifrit-legend-teste.apk e chamado-das-brasas-0.9.5-sons.apk).

## 0.9.5 (14/10/2026) — sons e músicas
- **Músicas:** 11 trilhas em loop com escalas árabes (hijaz, bayati, rast...), alaúde, qanun, ney e darbuka: título, vila e campo de cada região (deserto, costa e norte), casas, masmorras, luta de chefe e final. Vinhetas de nível, capítulo, missão, derrota e chefe vencido.
- **Efeitos:** espada, bola de fogo, explosão, fúria, dano, inimigos, passos, nado, itens, moedas, poção, baú, porta, montaria, rugido e fases do chefe, pedra, compra, sono e o "tic" das letras do diálogo. Botões e menus fazem clique.
- **Licença:** tudo livre (CC0): músicas e efeitos compostos por código para o jogo (tools/audio) e sons de interface do Kenney. Detalhes em game/assets/audio/LICENCAS.md e nos créditos.
- Volume de música e efeitos nas Configurações. APK com +5 MB.

## 0.9.5 (14/10/2026) — cenário v2
- Cenário v2 do fio de Artes: lagos, mares, cavernas e penhascos com contorno natural, praia em faixas, chão com transições suaves e interiores planejados (cômodos, móveis, 5 plantas de casa; casa da Samira e palácio refeitos).
  - tools/paisagem.py roda no fim de construir_mapas; tools/assar_cenario.py gera assets/cenario/mapas/<mapa>.png (rodar de novo sempre que um layout mudar).
  - Casas (lar_*): saída em (7,10), spawn porta em (7,9).
- Correção: o chão assado aparecia branco (a textura era liberada logo depois de desenhada).

## 0.9.4 (14/10/2026) — skins dos NPCs e cenário novo
- Skins Sunnyside (do fio de Artes) em 123 NPCs, aliados e 8 inimigos humanos, com animação de parado, andar, nadar e golpe e virando para 4 direções. Retratos novos nos diálogos.
  - Folhas compactadas por tools/compactar_skins.py (assets/personagens/npcs, inimigos, retratos); scripts/entities/skin_sprite.gd. Sem arquivo, cai no visual antigo.
- Cenário novo: tiles com bordas, casas, objetos e árvores altas (palmeira, redonda, pinheiro) no y-sort (assets/cenario/, tile_layer.gd do fio de Artes).
- Mapas e save não mudaram.

## 0.9.3 (14/10/2026) — lista 4: correções
- Nível máximo 30 → 80. Todos os níveis do jogo reescalados (tools/rebalancear_niveis.py, marcador data/balanco_v2.txt).
- 1º chefe (Rainha) exige ~nv 15: testado, nv 12 perde e nv 15 vence no limite. Zahrak ~nv 64. Portões: 15, 25, 33, 41, 49, 57.
- Diferença de nível pesa: inimigo acima do seu nível bate mais e apanha menos (e vice-versa).
- Chefes recuam depois de bater e rodeiam o Ifrit em vez de grudar.
- Save antigo: nível convertido para a escala nova (ex.: nv 10 → 31), vida cheia ao carregar.
- Diálogo: nomes compridos não são mais cortados embaixo do retrato.
- Pendente: skins novas dos NPCs (esperando o fio de Artes).

## 0.9.2 (13/10/2026)
- Skin nova do Ifrit (base Sunnyside World, de Daniel Diggle, modificada): animações de parado, andar, correr, golpe com a espada equipada, dano, morte e nado, nas 4 direções. A roupa muda com a armadura e a espada com a arma. Retrato novo nos diálogos. NPCs e inimigos continuam iguais.

## 0.9.1 (13/10/2026)
- O jogo agora se chama **Chamado das Brasas** (título, nome do app e créditos). Mesmo pacote: instala por cima e mantém o save.

## 0.9.0 (13/10/2026): a história da lista 3, inteira
- Escolhas desonestas em todos os capítulos: bolsa das caravanas, enganar o Kamal, o tesouro do Zeca, o baú do Grifo, o livro raro da biblioteca, moedas falsas do Vulto, o suborno do Varek e a proposta do Zahrak (fingir aceitar e atacar pelas costas). Desonestidade dá recompensa e tira honra; algumas missões falham. NPCs comentam quando a honra está baixa.
- Mais difícil e mais longo: EXP por nível +40%, inimigos +25% de vida e +20% de dano, chefes +40% de vida, portões de nível 1 a 2 níveis mais altos.
- Um final para cada aliado (Nadia, Bako, Omar, Kadir) e para o Ifrit: bom com honra 50 ou mais, ruim abaixo disso.
- Poema do fim no estilo do Minecraft (duas vozes falando do jogador), créditos e contador de segredos.
- Plot twist: a carta do pai era falsa. Cena pós-créditos com o Ancião Harun e o Oitavo Fogo, abrindo uma continuação. Depois do fim dá para continuar explorando (com novidades em Areia Rubra e na caverna do Zazu).
- 8 segredos e referências espalhados pelo mundo, incluindo "Conheça a ti mesmo".
- Diálogos: retrato do personagem agora fica à esquerda; escolhas longas quebram a linha.

## 0.8.0 (13/10/2026)
- Dormir na estalagem: a tela escurece como noite ("z Z z"), clareia num amanhecer laranja e a vida volta. Vale nas 5 estalagens.
- Dash removido. No lugar, o GOLPE ESPECIAL (Nova de Fogo): a barra de fúria enche batendo e matando; liberado depois de vencer a Rainha Escorpião. Guerreiro enche fúria 35% mais rápido.
- Montarias: Apito do Camelo (mercado de Miraj); hiena e lobo de metal podem ser domados com vida baixa (40%) usando a isca (Carne Seca / Engrenagem). Botão MONTAR; cai ao levar golpe, atacar ou entrar na água; não dá para montar em casas e cavernas.
- Física: movimento com aceleração e atrito (areia escorrega menos), inimigos atordoam ao bater na parede e empurram uns aos outros, tremor de tela (pode desligar em Configurações), pedras que se empurram.
- Cidades mais organizadas: caminhos até as portas, árvores alinhadas, flores nas entradas.
- Caminhos sem saída agora levam a algum lugar: Campo de Treino (bonecos, arena de 3 ondas, Mestre Sadiq), Cânion das Feras (inimigos do seu nível, renascem rápido), Aldeia das Tamareiras e Vila dos Pescadores (casas, lojas e missões novas).
- Tela especial de MISSÃO CONCLUÍDA (com recompensas) e MISSÃO FALHOU.
- Morte de chefe: carga de energia, câmera lenta, explosão e tremor antes da tela de vitória. Onda de choque dos chefes agora tem brechas seguras (verdes).
- Diálogos no estilo Stardew Valley: papel com moldura de madeira, retrato e nome do lado.
- Segredo: Ancião Zazu. Dica: uma pedra nas Dunas Rubras esconde algo. "Conheça a ti mesmo."
- NPCs nadam (crianças no canal da aldeia), assim como os aliados.
- Sinal de melhor (▲ verde), igual (—) ou pior (▼ vermelho) ao ver equipamento na loja e na bolsa.
- IA nova: caçadores dão bote avisado, matilhas cercam, atiradores atiram de longe, tanques resistem a empurrão, bichos fracos fogem com pouca vida. Aliados escolhem alvos perto do Ifrit, flanqueiam e os de longe mantêm distância.

## 0.7.2 (13/10/2026)
- Telas grandes: ao pular no meio da animação, os textos voltavam fora do centro. Agora se alinham no centro. Avisos longos (missão concluída, nome do mapa) crescem para os dois lados.
- Morrer na luta contra um chefe faz a luta recomeçar do zero: o chefe volta a dormir e a cena de aparição toca de novo.
- Inimigos batem e recuam (estilo clássico), em vez de ficar colados no Ifrit.
- Os botões de toque voltam depois de renascer.
- Cada chefe vencido deixa o mundo mais perigoso: inimigos com +20% de vida e +12% de dano por chefe, e chefes seguintes atacam mais rápido.

## 0.7.1 (13/10/2026)
- **Pente fino no formato do A35 (20:9):** todas as telas foram fotografadas e conferidas na tela larga.
- Tela de capítulo, chefe e vitória: texto agora fica centralizado em telas largas (antes ficava deslocado para a esquerda). O nome do mapa e os controles somem enquanto a tela aparece.
- Nova tela ao cair em combate ("Você caiu"), mostrando quanto perdeu e para onde volta.
- Mapa geral: regiões mais espaçadas e nomes de estradas ao lado, sem nomes encavalados.
- Câmbio começa em 10 (antes mostrava "1 Brasa → 0 Pérolas"). Pausa e câmbio sem espaço vazio sobrando.
- Bolsa: texto de ajuda certo em cada aba. Loja diz "Toque num item para comprar".

## 0.7.0 (13/10/2026)
- **Entradas coerentes:** a Estrada do Norte agora vira para o norte e chega pelo portão sul da Cidadela; a Ponte das Cinzas sobe uma escadaria até o portão sul do Trono Cinzento. Todas as ligações entre regiões foram conferidas.
- **Chefes mais difíceis:** vida triplicada e dano 60% maior. Três fases (66% e 33% de vida), cada uma mais rápida e com ataques novos: investida com aviso (em sequência nas fases finais), onda de choque que só se atravessa com DASH, espiral de projéteis e anéis duplos. Ao invocar lacaios o chefe fica com escudo por alguns segundos.
- **Poções:** espera de 1,5 s entre um consumível e outro (aparece no botão de atalho).
- **Telas de informação:** capítulo novo com faixas de cinema, ornamentos e as sete chamas do progresso; apresentação do chefe com nível e descrição; tela de "Chefe derrotado" com câmera lenta, tempo de luta, EXP e recompensas. Tocar pula. O Capítulo 2 ganhou sua tela.

## 0.6.0 (13/10/2026)
- **Caminho corrigido:** a saída norte do Vale dos Ventos agora desce uma encosta e chega pela borda sul do Mar de Areia (antes chegava pelo lado oeste). A estrada segue para o leste até Qadim.
- **Mapa geral:** ao tocar no mini mapa, a aba "Mapa geral" mostra o mundo. Cada região aparece quando você a visita, as vizinhas aparecem como "???" e dá para arrastar. Saves antigos já revelam os capítulos anteriores.
- **Equipamento:** slots de Arma e Armadura separados da bolsa. Armaduras novas nos ferreiros (Túnica de Couro, Cota de Malha, Armadura de Coral, do Vento e de Sal) reduzem o dano recebido.
- **Bolsa estilo Resident Evil:** grade onde cada item ocupa seu tamanho (espada 1x3, armadura 2x2, cantil 1x2, o resto 1x1), com pilhas. Dá para mover, girar, combinar (erva + erva = poção, poção + erva = poção média, cantil + erva = antídoto...) e organizar sozinho.
- **Itens importantes** (cartas, pergaminhos, amuleto) ficam numa aba própria e não ocupam espaço.
- **Baú:** o que não cabe vai para o baú, que abre em cidades e dentro das casas. Bolsas maiores à venda nos mercados (7x4 e 8x5).
- **Save:** o save atual é convertido sozinho para a nova bolsa. O APK instala por cima sem perder o progresso.

## 0.5.0 (13/10/2026)
- **Casas:** as 26 casas das cidades agora abrem, com 31 moradores novos para conversar. Alguns pedem ajuda, outros contam histórias, e as falas mudam depois de cada chefe.
- **Honra:** escolhas morais nas casas (ajudar, aceitar suborno, pegar o cofrinho de uma criança, denunciar contrabando...). A honra vai de Desonrado a Herói do Povo e muda o preço das lojas.
- **Hierarquia:** Aprendiz, Andarilho, Guardião, Campeão e Lenda das Chamas, conforme chefes vencidos, missões e honra.
- **Classe única:** a Mestra Zaira, na Casa das Três Ordens do Oásis de Miraj, ensina Guerreiro, Feiticeiro ou Clérigo a partir do nível 5. A escolha é para sempre.
- **Nível mínimo:** as estradas para regiões perigosas pedem nível mínimo (3, 6, 9, 12, 15 e 18).
- **Drops:** cada inimigo tem sua tabela; os itens saltam para fora, os raros brilham, chefes sempre deixam recompensa e às vezes caem corações.
- **Efeitos de status:** veneno (cobras), queimadura (fogo) e lentidão (sombras), mostrados no topo da tela. O Antídoto cura e está à venda nos mercados.

## 0.4.0 (13/10/2026)
- **Física:** inimigos não se amontoam nem entram no Ifrit; param encostados nele.
- **Terreno:** na areia anda um pouco mais devagar, no caminho e na ponte mais rápido. Na água o Ifrit nada: fica mais lento, só aparece da cintura para cima e não ataca. Inimigos que andam e NPCs não entram na água.
- **Dash:** botão DASH (Shift ou U no PC). Arrancada curta, sem levar dano durante ela, recarga de 1,2 s.
- **Recargas visíveis:** GOLPE, FOGO e DASH mostram uma fatia escura enquanto recarregam.
- **Inimigos:** cada um tem nível. Barra de vida aparece de perto; nome e nível aparecem bem de perto ou ao levar dano (nome em vermelho quando o inimigo é bem mais forte).
- **NPCs:** o nome aparece quando o Ifrit chega perto.
- **EXP:** varia com a diferença de nível (até o dobro contra inimigos mais fortes, bem menos contra os fracos). Aparece "+N EXP" ao derrotar.
- **Subir de nível:** coluna de luz, anéis dourados e faíscas em volta do Ifrit.
- **Atalho:** botão com o item escolhido (começa com a Poção Pequena) e a quantidade. Para trocar, Bolsa > item > "Pôr no atalho". Tecla R no PC.
- **Pausa:** Continuar, ícones de Bolsa, Missões e Mapa, Configurações e Salvar e sair.

## 0.3.0 (13/10/2026)
- **Chefe multiplicado:** a cena de aparição rodava de novo a cada vez que o Ifrit cruzava a entrada da sala e invocava outro chefe. Agora só existe um chefe por sala.
- **Cena travando:** um passo de cena que vira um personagem para outro travava se esse personagem não estivesse no mapa.
- **Controles:** joystick maior, com modo Fixo ou Livre e zona morta; botões GOLPE (maior, no canto), FOGO e FALAR em arco com ícones. FOGO fica apagado até aprender a magia.
- **Barra superior:** botões de pausa, bolsa e missões ao lado do mini mapa.
- **Mini mapa:** mostra o Ifrit, quem quer falar com você, saídas, inimigos e chefe. Tocar nele abre o mapa completo.
- **Menu de pausa:** Continuar, Bolsa, Missões, Mapa, Configurações, Salvar jogo e Voltar ao título. O botão "voltar" do Android abre a pausa, e o jogo pausa sozinho ao voltar para o app.
- **Configurações:** tamanho do joystick e dos botões, modo do joystick, opacidade dos controles, velocidade do texto, mini mapa, volume de música e efeitos. Salvas no aparelho.
- **Diálogo:** retrato de quem fala, nome numa aba, seta piscando para avançar, narração em outra cor e escolhas em lista.
- Teclas no PC: Esc ou P pausa.

## 0.2.0 (13/10/2026)
- Calango com a arte original (o dobro da altura do Ifrit) e animação de andar.
- Joystick renomeado para TouchJoystick (compatível com Godot 4.7).
- Diálogo não avança duas vezes por toque.
- Salvamento a cada progresso e ao ir para o fundo (antes só ao trocar de mapa).
- Joystick e botões se soltam se o toque for cancelado.
- Preset de exportação Android, texturas ETC2/ASTC e ícone.

## 0.1.0 (13/10/2026)
- Modo história completo: 7 capítulos, 22 mapas, 80 NPCs, 45 missões, 7 chefes, 4 aliados, inventário, lojas e câmbio.
