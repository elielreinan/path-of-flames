"""Interiores das casas das cidades, moradores, escolhas de honra e portões por nível.
Chamado por construir_mapas.build_all() depois de montar os mapas das cidades.
Tudo que este script cria usa o prefixo "lar_" para poder ser refeito sem duplicar.
"""
import json, os

DATA = os.path.join(os.path.dirname(__file__), "..", "data")
SOLID = set("#HRTWrmbXCS JKwhE")

CIDADES = {
    "areia_rubra": ("brasas", "chefe_rainha"),
    "oasis_miraj": ("brasas", "chefe_serpente"),
    "porto_coral": ("perolas", "chefe_kraal"),
    "vale_ventos": ("perolas", "chefe_grifo"),
    "ruinas_qadim": ("coroas", "chefe_golem"),
    "cidadela_sal": ("coroas", "chefe_varek"),
}

# Nível mínimo para entrar em cada região (aviso educado em vez de deixar o jogador morrer).
# Subiram ~2 por capítulo: é preciso fazer missões secundárias, o Cânion das Feras e o Campo de Treino.
PORTOES = {"estrada_caravanas": 15, "desfiladeiro_sal": 25, "trilha_penhascos": 33,
           "mar_de_areia": 41, "estrada_norte": 49, "ponte_cinzas": 57}

NPCS = {}
DIALOGOS = {}


def ap(cabelo="curto", corpo="tunica", h="#2a1a10", b="#8a5a3a", a="#c0a060", barba=False, crianca=False):
    out = {"cabelo": cabelo, "cores": {"h": h, "b": b, "a": a}}
    if not crianca:
        out["corpo"] = corpo
    if barba:
        out["barba"] = True
        out["cores"]["B"] = h
    if crianca:
        out["crianca"] = True
    return out


def fala(*linhas):
    """Linhas no formato "Quem: texto". Sem prefixo é narração."""
    out = []
    for l in linhas:
        s, _, t = l.partition(": ") if ": " in l[:24] else ("", "", l)
        out.append({"s": s, "t": t})
    return out


def d(did, *linhas, escolhas=None, acoes=None):
    data = {"linhas": fala(*linhas)}
    if escolhas:
        data["escolhas"] = escolhas
    if acoes:
        data["acoes"] = acoes
    DIALOGOS[did] = data
    return did


def esc(texto, acoes=None, ir=None, se=None):
    c = {"t": texto}
    if acoes:
        c["acoes"] = acoes
    if ir:
        c["ir"] = ir
    if se:
        c["se"] = se
    return c


def morador(nid, nome, aparencia, falas):
    NPCS[nid] = {"nome": nome, "aparencia": aparencia, "falas": falas}
    return nid


def f(dialogo, se=None, importante=False):
    out = {"dialogo": dialogo}
    if se:
        out["se"] = se
    if importante:
        out["importante"] = True
    return out


# ---------------------------------------------------------------------
# Moradores por casa (na ordem das portas de cada cidade, de cima para baixo, da esquerda para a direita).
# Cada casa: lista de (id, posição dentro da casa).
# ---------------------------------------------------------------------

def areia_rubra():
    chefe = "chefe_rainha"
    yield [(morador("lar_farida", "Farida, a tecelã", ap("veu", "manto", b="#a03a3a", a="#e0b040"), [
        f("lar_farida_obrigada", {"flag": "lar_farida_ajudou"}),
        f("lar_farida_pede", importante=True)]), (3, 3))]
    d("lar_farida_pede",
      "Farida: Ifrit! Que bom que entrou. Estes tapetes vão para a caravana e minhas costas não aguentam mais.",
      "Farida: Pode me ajudar a enrolar os maiores?",
      escolhas=[esc("Claro, eu ajudo.", [{"flag": "lar_farida_ajudou"}, {"honra": 3}, {"dar_item": "tamara", "qtd": 2}], "lar_farida_feito"),
                esc("Agora não posso.")])
    d("lar_farida_feito", "Você enrola os tapetes pesados, um por um.",
      "Farida: Abençoado seja! Leve estas tâmaras, foram colhidas hoje.")
    d("lar_farida_obrigada", "Farida: Os tapetes chegaram inteiros ao Oásis. Você tem mãos boas, Ifrit.")

    yield [(morador("lar_rania", "Rania", ap("longo", "tunica", h="#3a2010", b="#4a7a5a"), [
        f("lar_rania_depois", {"flag": chefe}),
        f("lar_rania_padrao")]), (8, 4))]
    descanso = [esc("Descansar um pouco.", [{"curar": True}], "lar_descansou"), esc("Estou bem, obrigado.")]
    d("lar_descansou", "Você descansa e recupera as forças.")
    d("lar_rania_padrao", "Rania: Meu avô Harun vive dizendo que você é cabeça dura. Ele gosta de você.",
      "Rania: Se estiver cansado, a esteira ali está limpa.", escolhas=descanso)
    d("lar_rania_depois", "Rania: Você venceu a Rainha Escorpião! A cidade inteira está falando nisso.",
      "Rania: Descanse um pouco antes de partir.", escolhas=descanso)

    yield [(morador("lar_basim", "Basim, o oleiro", ap("turbante", "tunica", b="#8a6a4a", a="#5a3a2a", barba=True), [
        f("lar_basim_obrigado", {"flag": "lar_basim_ajudou"}),
        f("lar_basim_pede", importante=True)]), (3, 3)),
           (morador("lar_jamil", "Jamil", ap("curto", crianca=True, b="#c0a070"), [f("lar_jamil")]), (9, 3))]
    d("lar_basim_pede", "Basim: Meu filho Jamil pegou a febre do deserto. O remédio custa 5 brasas e meus potes não vendem.",
      "Basim: Não tenho coragem de pedir, mas...",
      escolhas=[esc("Tome 5 brasas.", [{"pagar": "brasas", "qtd": 5}, {"flag": "lar_basim_ajudou"}, {"honra": 4}], "lar_basim_feito",
                    se={"moeda": {"brasas": 5}}),
                esc("Não tenho como ajudar agora.")])
    d("lar_basim_feito", "Basim: Que a Chama te proteja, rapaz. Nunca vou esquecer.")
    d("lar_basim_obrigado", "Basim: Jamil já está de pé! Ele agora quer ser guardião como você.")
    d("lar_jamil", "Jamil: *cof cof* Quando eu crescer vou ter uma espada de fogo igual a sua!")

    yield [(morador("lar_hana", "Hana", ap("veu", "manto", b="#5a4a8a", a="#d0c0a0"), [f("lar_hana")]), (3, 3)),
           (morador("lar_tamir", "Tamir", ap("curto", "tunica", b="#6a5a3a", barba=True), [f("lar_tamir")]), (4, 3)),
           (morador("lar_dina", "Dina", ap("longo", crianca=True, h="#5a2a10", b="#d07050"), [
               f("lar_dina_triste", {"flag": "lar_dina_cofre_pego"}),
               f("lar_dina_cofre", {"sem_flag": "lar_dina_cofre_visto"}, importante=True),
               f("lar_dina")]), (9, 5))]
    d("lar_hana", "Hana: Tamir trabalha dobrado desde que a estrada fechou. Tudo está caro.")
    d("lar_tamir", "Tamir: Ifrit, o guardião! Fique à vontade, a casa é simples mas é sua.")
    d("lar_dina_cofre", "Dina saiu correndo para brincar e deixou o cofrinho de barro aberto em cima da mesa.",
      "Dentro dele brilham algumas brasas, as economias de uma criança.",
      escolhas=[esc("Pegar as moedas.", [{"moeda": "brasas", "qtd": 3}, {"honra": -6}, {"flag": "lar_dina_cofre_pego"},
                                         {"flag": "lar_dina_cofre_visto"}]),
                esc("Fechar o cofrinho e deixar.", [{"honra": 2}, {"flag": "lar_dina_cofre_visto"}])])
    d("lar_dina", "Dina: Estou juntando brasas para comprar um camelo! Já tenho quase três.")
    d("lar_dina_triste", "Dina: Alguém pegou as brasas do meu cofrinho... *snif*")

    yield [(morador("lar_jafar", "Velho Jafar", ap("careca", "manto", h="#d0d0d0", b="#e0d8c0", a="#8a5a2a", barba=True), [
        f("lar_jafar_depois", {"flag": "lar_jafar_tamara"}),
        f("lar_jafar")]), (8, 4))]
    d("lar_jafar", "Jafar: Sabe por que a cidade se chama Areia Rubra? Dizem que a primeira Chama caiu do céu aqui e tingiu as dunas.",
      "Jafar: Bobagem, eu acho. A areia é vermelha por causa do ferro. Mas a história é mais bonita.",
      "Jafar: Tome uma tâmara. Velho não precisa de muita.", acoes=[{"dar_item": "tamara"}, {"flag": "lar_jafar_tamara"}])
    d("lar_jafar_depois", "Jafar: Seu pai Kadir também vinha ouvir minhas histórias. Sentava aí mesmo onde você está.")


def oasis_miraj():
    chefe = "chefe_serpente"
    yield [(morador("lar_zaira", "Mestra Zaira", ap("capuz", "manto", h="#e0e0e0", b="#3a2a5a", a="#e0a020"), [
        f("lar_zaira_guerreiro", {"classe": "guerreiro"}),
        f("lar_zaira_feiticeiro", {"classe": "feiticeiro"}),
        f("lar_zaira_clerigo", {"classe": "clerigo"}),
        f("lar_zaira_escolha", {"nivel": 10}, importante=True),
        f("lar_zaira_cedo")]), (6, 3))]
    d("lar_zaira_cedo", "Zaira: Esta é a Casa das Três Ordens: Guerreiros, Feiticeiros e Clérigos.",
      "Zaira: Cada guardião só pode seguir uma ordem, e a escolha é para sempre.",
      "Zaira: Você ainda é muito verde. Volte quando chegar ao nível 5.")
    d("lar_zaira_escolha", "Zaira: Você cresceu, Ifrit. Já pode escolher sua ordem.",
      "Zaira: GUERREIRO: golpes 30% mais fortes, mais vida e dash que recarrega rápido.",
      "Zaira: FEITICEIRO: bola de fogo 50% mais forte e com metade da recarga.",
      "Zaira: CLÉRIGO: recupera vida sozinho, cura mais com poções e é imune a veneno.",
      "Zaira: Pense bem. Não há volta.",
      escolhas=[esc("Guerreiro", [{"classe": "guerreiro"}], "lar_zaira_guerreiro"),
                esc("Feiticeiro", [{"classe": "feiticeiro"}], "lar_zaira_feiticeiro"),
                esc("Clérigo", [{"classe": "clerigo"}], "lar_zaira_clerigo"),
                esc("Ainda vou pensar.")])
    d("lar_zaira_guerreiro", "Zaira: Um Guerreiro protege com o próprio corpo. Que sua lâmina nunca hesite.")
    d("lar_zaira_feiticeiro", "Zaira: Um Feiticeiro carrega a Chama dentro de si. Não deixe que ela te consuma.")
    d("lar_zaira_clerigo", "Zaira: Um Clérigo cura antes de ferir. É a ordem mais difícil de todas.")

    yield [(morador("lar_selma", "Selma, a curandeira", ap("veu", "manto", b="#e0e0d0", a="#3a8a5a"), [
        f("lar_selma")]), (3, 3))]
    d("lar_selma", "Selma: Sente-se. Vou passar um unguento de lótus nessas feridas.",
      escolhas=[esc("Aceitar o tratamento.", [{"curar": True}], "lar_descansou"), esc("Não precisa.")])

    yield [(morador("lar_idris", "Idris, o mercador", ap("turbante", "manto", b="#2a5a8a", a="#e0c040", barba=True), [
        f("lar_idris_depois", {"flag": "lar_idris_decidiu"}),
        f("lar_idris_suborno", importante=True)]), (8, 4))]
    d("lar_idris_suborno", "Idris: Guardião... Dizem que você tem a confiança do Sheik.",
      "Idris: Se disser a ele que minhas taxas da água estão em dia, essas 20 brasas são suas. Ninguém precisa saber.",
      escolhas=[esc("Aceitar as brasas.", [{"moeda": "brasas", "qtd": 20}, {"honra": -8}, {"flag": "lar_idris_decidiu"}], "lar_idris_aceitou"),
                esc("Recusar. A água é de todos.", [{"honra": 4}, {"flag": "lar_idris_decidiu"}], "lar_idris_recusou")])
    d("lar_idris_aceitou", "Idris: Homem esperto! Vamos nos dar muito bem.")
    d("lar_idris_recusou", "Idris: Hunf. Honra não enche barriga, rapaz.")
    d("lar_idris_depois", "Idris: Negócios são negócios, guardião.")

    yield [(morador("lar_amal", "Amal", ap("longo", "tunica", h="#1a1010", b="#c08030"), [
        f("lar_amal_depois", {"flag": chefe}),
        f("lar_amal")]), (4, 4))]
    d("lar_amal", "Amal: O oásis está secando e todos dizem que é a serpente das águas. Tenho medo de buscar água à noite.")
    d("lar_amal_depois", "Amal: A água voltou a correr! Obrigada, Ifrit. Meus filhos podem brincar no lago de novo.",
      acoes=[{"flag": "lar_amal_agradeceu"}])


def porto_coral():
    chefe = "chefe_kraal"
    yield [(morador("lar_rafi", "Rafi, o pescador", ap("curto", "tunica", h="#3a2a1a", b="#3a6a8a", barba=True), [
        f("lar_rafi_presente", {"flag": chefe, "sem_flag": "lar_rafi_peixe"}, importante=True),
        f("lar_rafi_depois", {"flag": chefe}),
        f("lar_rafi")]), (3, 3))]
    d("lar_rafi", "Rafi: Desde que o Kraal apareceu, nenhum barco volta cheio. Minhas redes estão secando na parede.")
    d("lar_rafi_presente", "Rafi: Voltei do mar com a rede cheia! Isso é graças a você. Leve uns peixes.",
      acoes=[{"dar_item": "peixe", "qtd": 3}, {"flag": "lar_rafi_peixe"}])
    d("lar_rafi_depois", "Rafi: O mar está calmo. Até as gaivotas parecem mais felizes.")

    yield [(morador("lar_mara", "Viúva Mara", ap("veu", "manto", b="#2a2a3a", a="#6a6a7a"), [
        f("lar_mara_depois", {"flag": chefe}), f("lar_mara")]), (8, 4))]
    d("lar_mara", "Mara: Meu marido saiu para pescar no dia em que a névoa chegou. Ainda acendo uma vela na janela.")
    d("lar_mara_depois", "Mara: Disseram que você derrotou a fera do mar. Hoje apaguei a vela. Acho que ele descansa agora.")

    yield [(morador("lar_nuno", "Velho Nuno", ap("careca", "tunica", h="#e0e0e0", b="#5a7a6a", barba=True), [
        f("lar_nuno")]), (8, 3))]
    d("lar_nuno", "Nuno: Nas noites de lua cheia dá para ver luzes no fundo do mar. São as cidades antigas que afundaram.",
      "Nuno: Os de Qadim construíram tudo isso. Gente sábia, mas orgulhosa demais.")

    yield [(morador("lar_iara", "Iara, a costureira", ap("longo", "tunica", h="#6a2a1a", b="#d08090"), [
        f("lar_iara")]), (3, 3))]
    d("lar_iara", "Iara: Velas de barco, roupas, redes... Se rasga, eu costuro.",
      "Iara: Só não me peça para costurar coração partido. Esse não tem jeito.")

    yield [(morador("lar_tito", "Tito", ap("curto", crianca=True, h="#1a1a1a", b="#3a8ac0"), [
        f("lar_tito_depois", {"flag": "lar_tito_respondeu"}), f("lar_tito", importante=True)]), (3, 4)),
           (morador("lar_lia", "Lia", ap("longo", crianca=True, h="#8a4a1a", b="#e0a040"), [f("lar_lia")]), (8, 4))]
    d("lar_tito", "Tito: A gente tá brincando de pirata! Ser pirata é legal, né? Eles têm tesouro e ninguém manda neles!",
      escolhas=[esc("Pirata rouba os outros. Não é legal.", [{"honra": 2}, {"flag": "lar_tito_respondeu"}], "lar_tito_bom"),
                esc("Pirata é o máximo!", [{"honra": -2}, {"flag": "lar_tito_respondeu"}], "lar_tito_mau")])
    d("lar_tito_bom", "Tito: Hmm... então eu vou ser guardião igual você!")
    d("lar_tito_mau", "Tito: EBA! Lia, vou roubar seu doce!", "Lia: MÃÃÃE!")
    d("lar_tito_depois", "Tito: Lia, você é o monstro do mar e eu sou o herói!")
    d("lar_lia", "Lia: O Tito sempre quer ser o herói. Um dia eu vou ser a heroína.")

    yield [(morador("lar_gaspar", "Gaspar", ap("capuz", "manto", h="#2a2a2a", b="#3a3a2a", barba=True), [
        f("lar_gaspar_depois", {"flag": "lar_gaspar_decidiu"}), f("lar_gaspar", importante=True)]), (8, 4))]
    d("lar_gaspar", "Você nota caixotes com o selo da Cidadela de Sal escondidos sob uma lona. Contrabando.",
      "Gaspar: Viu nada, guardião. Toma três pérolas e esquece essa casa.",
      escolhas=[esc("Aceitar e fingir que não viu.", [{"moeda": "perolas", "qtd": 3}, {"honra": -3}, {"flag": "lar_gaspar_decidiu"}],
                    "lar_gaspar_aceitou"),
                esc("Avisar a guarda do porto.", [{"honra": 5}, {"flag": "lar_gaspar_decidiu"}, {"flag": "lar_gaspar_preso"}],
                    "lar_gaspar_denunciou")])
    d("lar_gaspar_aceitou", "Gaspar: Assim que eu gosto. Gente prática.")
    d("lar_gaspar_denunciou", "Gaspar: Você vai se arrepender, moleque!", "A guarda leva Gaspar e os caixotes.")
    d("lar_gaspar_depois", "Gaspar: Some daqui.")
    NPCS["lar_gaspar"]["falas"].insert(0, f("lar_gaspar_vazio", {"flag": "lar_gaspar_preso"}))
    d("lar_gaspar_vazio", "A casa de Gaspar está vazia. Só restou uma lona velha no chão.")


def vale_ventos():
    chefe = "chefe_grifo"
    yield [(morador("lar_edite", "Pastora Edite", ap("veu", "tunica", b="#8a7a5a", a="#e0e0d0"), [f("lar_edite")]), (3, 3))]
    d("lar_edite", "Edite: As cabras sentem o vento mudar antes de qualquer um. Descanse, o leite está quente.",
      escolhas=[esc("Descansar.", [{"curar": True}], "lar_descansou"), esc("Obrigado, sigo viagem.")])

    yield [(morador("lar_bruno", "Bruno, o aprendiz", ap("curto", "tunica", h="#a07030", b="#6a8a3a"), [
        f("lar_bruno_depois", {"flag": chefe}), f("lar_bruno")]), (8, 4))]
    d("lar_bruno", "Bruno: Estou aprendendo a fazer sinos de vento. Os grifos odeiam o barulho... ou adoram, ninguém sabe.")
    d("lar_bruno_depois", "Bruno: Fiz um sino em sua homenagem. Ele toca uma nota grave, igual a um rugido de grifo.")

    yield [(morador("lar_celeste", "Vovó Celeste", ap("veu", "manto", h="#e0e0e0", b="#8a5a8a", a="#e0d0b0"), [
        f("lar_celeste_depois", {"flag": "lar_celeste_lenha"}), f("lar_celeste", importante=True)]), (3, 3))]
    d("lar_celeste", "Celeste: Meu neto foi para a cidade e a lenha acabou. O frio aqui em cima é cruel.",
      escolhas=[esc("Eu busco a lenha.", [{"honra": 3}, {"flag": "lar_celeste_lenha"}, {"dar_item": "pao", "qtd": 2}], "lar_celeste_feito"),
                esc("Agora não posso.")])
    d("lar_celeste_feito", "Você carrega várias braçadas de lenha até a lareira.",
      "Celeste: Que menino bom! Leve pão, assei hoje cedo.")
    d("lar_celeste_depois", "Celeste: A lareira não apagou desde aquele dia. Volte para comer pão quando quiser.")

    yield [(morador("lar_silas", "Eremita Silas", ap("capuz", "manto", h="#6a6a6a", b="#4a4a3a", barba=True), [f("lar_silas")]), (8, 3))]
    d("lar_silas", "Silas: Vim para o vale fugir das pessoas, e as pessoas vêm até mim. Que ironia.",
      "Silas: Já que veio: quem busca a Chama com raiva acaba queimado. Lembre disso.")

    yield [(morador("lar_ana", "Ana", ap("longo", "manto", h="#3a2010", b="#c0c0e0"), [f("lar_ana")]), (3, 4))]
    d("lar_ana", "Ana: Shhh! O bebê finalmente dormiu. O vento uivou a noite toda.")


def ruinas_qadim():
    yield [(morador("lar_yara", "Yara, a arqueóloga", ap("curto", "tunica", h="#6a3a1a", b="#b09060", a="#5a3a1a"), [f("lar_yara")]), (3, 3))]
    d("lar_yara", "Yara: Estes símbolos falam de um povo que domava o fogo como se fosse água.",
      "Yara: Se o que estou lendo for verdade, a Chama não é uma arma. É uma promessa.")

    yield [(morador("lar_malik", "Malik, o escriba", ap("turbante", "manto", b="#3a5a3a", a="#d0b060", barba=True), [
        f("lar_malik_depois", {"flag": "lar_malik_ajudou"}), f("lar_malik", importante=True)]), (8, 4))]
    d("lar_malik", "Malik: Tenho que copiar estas tábuas antes que a areia apague tudo. Pode segurar a lamparina?",
      escolhas=[esc("Seguro, sim.", [{"honra": 3}, {"flag": "lar_malik_ajudou"}, {"xp": 40}], "lar_malik_feito"),
                esc("Não tenho tempo.")])
    d("lar_malik_feito", "Horas passam enquanto Malik copia símbolos antigos. Você aprende um pouco sobre eles.",
      "Malik: Obrigado. Você tem paciência de escriba.")
    d("lar_malik_depois", "Malik: Já copiei metade. A outra metade fala de um tal Zahrak.")


def cidadela_sal():
    chefe = "chefe_varek"
    yield [(morador("lar_caio", "Caio, soldado ferido", ap("curto", "armadura", h="#3a2a1a", b="#8a8a9a"), [
        f("lar_caio_depois", {"flag": "lar_caio_ajudado"}), f("lar_caio", importante=True)]), (3, 3))]
    d("lar_caio", "Caio: Fui ferido na muralha e o capitão me mandou para casa. Sem poção, a perna não fecha.",
      escolhas=[esc("Dar uma Poção Pequena.", [{"remover_item": "pocao_pequena"}, {"honra": 6}, {"flag": "lar_caio_ajudado"}],
                    "lar_caio_feito", se={"item": "pocao_pequena"}),
                esc("Não tenho como ajudar.")])
    d("lar_caio_feito", "Caio: Já sinto a perna! Se precisar de um escudo ao seu lado, me chame.")
    d("lar_caio_depois", "Caio: Voltei a treinar. Ainda manco, mas manco com orgulho.")

    yield [(morador("lar_lucia", "Lúcia", ap("veu", "tunica", b="#6a5a5a"), [
        f("lar_lucia_depois", {"flag": "lar_desertor_decidiu"}), f("lar_lucia", importante=True)]), (3, 3)),
           (morador("lar_davi", "Davi, o desertor", ap("curto", "tunica", h="#2a1a10", b="#5a5a4a", barba=True), [
               f("lar_davi")], ), (9, 4))]
    NPCS["lar_davi"]["falas"].insert(0, f("lar_davi_preso", {"flag": "lar_davi_entregue"}))
    d("lar_lucia", "Lúcia: Por favor, guardião... Meu marido Davi fugiu do exército de Varek. Ele não queria lutar contra o próprio povo.",
      "Lúcia: Há uma recompensa de 5 coroas por ele. Você vai entregá-lo?",
      escolhas=[esc("Entregar Davi aos guardas.", [{"moeda": "coroas", "qtd": 5}, {"honra": -6}, {"flag": "lar_desertor_decidiu"},
                                                    {"flag": "lar_davi_entregue"}, {"sumir_npc": "lar_davi"}], "lar_lucia_entregou"),
                esc("Ninguém vai saber por mim.", [{"honra": 5}, {"flag": "lar_desertor_decidiu"}], "lar_lucia_poupou")])
    d("lar_lucia_entregou", "Os guardas levam Davi. Lúcia não diz mais nada.")
    d("lar_lucia_poupou", "Lúcia: Obrigada... obrigada! Você é diferente dos soldados de Varek.")
    d("lar_lucia_depois", "Lúcia: Faça o que achar certo, guardião. Eu também fiz.")
    d("lar_davi", "Davi: Recusei atirar em gente do porto. Se isso é traição, sou traidor com orgulho.")
    d("lar_davi_preso", "A cama de Davi está vazia.")

    yield [(morador("lar_vera", "Vera", ap("veu", "manto", h="#c0c0c0", b="#4a3a5a"), [
        f("lar_vera_depois", {"flag": chefe}), f("lar_vera")]), (8, 3))]
    d("lar_vera", "Vera: Varek é meu filho. Era um menino gentil antes da sombra entrar no coração dele.")
    d("lar_vera_depois", "Vera: Soube o que aconteceu com Varek. Não te culpo, Ifrit.",
      "Vera: Antes do fim, ele mandou um recado: pediu perdão. Eu já perdoei. Você também deveria se perdoar.")

    yield [(morador("lar_otto", "Otto, o cozinheiro", ap("careca", "tunica", b="#e0e0e0", a="#c05030", barba=True), [
        f("lar_otto_comeu", {"flag": "lar_otto_pao"}), f("lar_otto")]), (8, 4))]
    d("lar_otto", "Otto: Cozinho para a guarnição inteira. Ouço tudo: dizem que o Varek não dorme há semanas.",
      "Otto: Toma, pão do quartel. Duro, mas sustenta.", acoes=[{"dar_item": "pao", "qtd": 2}, {"flag": "lar_otto_pao"}])
    d("lar_otto_comeu", "Otto: Os soldados andam nervosos. Dizem que alguma coisa se mexe nas Ruínas de Qadim.")


CONTEUDO = {"areia_rubra": areia_rubra, "oasis_miraj": oasis_miraj, "porto_coral": porto_coral,
            "vale_ventos": vale_ventos, "ruinas_qadim": ruinas_qadim, "cidadela_sal": cidadela_sal}

MOVEIS = [  # variações de mobília (posições dentro de 12x9)
    {"E": [(1, 2), (2, 2)], "b": [(10, 2), (10, 3)], "m": [(5, 5), (6, 5)], "K": [(10, 6)]},
    {"E": [(9, 2), (10, 2)], "b": [(1, 2), (1, 3)], "m": [(6, 3)], "h": []},
    {"b": [(10, 2), (10, 3), (9, 2), (9, 3)], "m": [(4, 5), (5, 5)], "K": [(1, 6), (1, 5)]},
]


def _interior(Grid, n, ocupado):
    g = Grid(12, 9, "f")
    g.rect(0, 0, 12, 2, "w")
    g.vline(0, 0, 8, "w")
    g.vline(11, 0, 8, "w")
    g.hline(0, 11, 8, "w")
    g.rect(4, 6, 4, 1, "P")
    for ch, spots in MOVEIS[n % len(MOVEIS)].items():
        for x, y in spots:
            if (x, y) not in ocupado and (x, y) != (6, 7):
                g.put(x, y, ch)
    g.put(6, 8, "D")
    return g


def _livre(layout, x, y):
    return 0 <= y < len(layout) and 0 <= x < len(layout[y]) and layout[y][x] not in SOLID


def build(Grid, register, area, MAPS):
    NPCS.clear()
    DIALOGOS.clear()
    for city, (moeda, _chefe) in CIDADES.items():
        cdata = MAPS[city]
        layout = cdata["layout"]
        usadas = set()
        for w in cdata.get("saidas", []):
            ax, ay, aw, ah = w["area"]
            usadas |= {(x, y) for x in range(ax, ax + aw) for y in range(ay, ay + ah)}
        portas = [(x, y) for y, row in enumerate(layout) for x, ch in enumerate(row) if ch == "D" and (x, y) not in usadas]
        portas.sort(key=lambda p: (p[1], p[0]))
        casas = list(CONTEUDO[city]())
        assert len(casas) == len(portas), f"{city}: {len(portas)} portas para {len(casas)} casas"
        for n, ((dx, dy), moradores) in enumerate(zip(portas, casas), 1):
            mid = f"lar_{city}_{n}"
            fora = next(p for p in [(dx, dy + 1), (dx - 1, dy + 1), (dx + 1, dy + 1), (dx, dy + 2)] if _livre(layout, *p))
            cdata["spawns"][f"lar_{n}"] = list(fora)
            cdata["saidas"].append({"area": area(dx, dy), "mapa": mid, "spawn": "porta"})
            g = _interior(Grid, n, {p for _, p in moradores})
            nome = NPCS[moradores[0][0]]["nome"].split(",")[0]
            register(mid, g, nome=f"Casa de {nome}", moeda=moeda, interior=True,
                     spawns={"porta": [6, 7]},
                     npcs=[{"id": nid, "pos": list(pos)} for nid, pos in moradores],
                     saidas=[{"area": area(6, 8), "mapa": city, "spawn": f"lar_{n}"}],
                     renascer=cdata.get("renascer", [city, f"lar_{n}"]))
    # Pós-jogo: depois do Oitavo Fogo, Harun some e deixa um bilhete na mesa da casa dele (a de Rania, neta dele).
    MAPS["lar_areia_rubra_2"]["npcs"].append({"id": "lar_x_bilhete_harun", "pos": [5, 4], "se": {"flag": "oitavo_fogo"}})
    # Portões por nível nas entradas das regiões perigosas.
    for data in MAPS.values():
        for w in data.get("saidas", []):
            if w["mapa"] in PORTOES:
                w["nivel"] = PORTOES[w["mapa"]]
    # NPCs e diálogos.
    path = os.path.join(DATA, "npcs.json")
    with open(path, encoding="utf-8") as fh:
        npcs = {k: v for k, v in json.load(fh).items() if not k.startswith("lar_")}
    npcs.update(NPCS)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(npcs, fh, ensure_ascii=False, indent=1)
    with open(os.path.join(DATA, "dialogos", "casas.json"), "w", encoding="utf-8") as fh:
        json.dump(DIALOGOS, fh, ensure_ascii=False, indent=1)
    print("casas:", sum(1 for m in MAPS if m.startswith("lar_")), "moradores:", len(NPCS), "diálogos:", len(DIALOGOS))
