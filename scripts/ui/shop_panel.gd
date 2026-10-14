class_name ShopPanel
extends Control
## Loja: compra e venda na moeda local.

signal closed

var shop_id := ""
var _shop := {}
var _list: VBoxContainer
var _money: Label
var _info: Label
var _selling := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shop = Data.shops[shop_id]
	var w := UiKit.window(_shop.nome, Vector2(400, 230))
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())
	var tabs := HBoxContainer.new()
	w.box.add_child(tabs)
	var buy := UiKit.button("Comprar")
	buy.pressed.connect(func(): _selling = false; _refresh())
	tabs.add_child(buy)
	var sell := UiKit.button("Vender")
	sell.pressed.connect(func(): _selling = true; _refresh())
	tabs.add_child(sell)
	_money = UiKit.label("", 9, Color(1, 0.85, 0.3))
	_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tabs.add_child(_money)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 140)
	w.box.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_info = UiKit.label("Toque num item para comprar.", 9, UiKit.MUTED)
	w.box.add_child(_info)
	_refresh()


func _price(id: String) -> int:
	# Preço base (em brasas) convertido para a moeda da loja.
	var base := float(Data.item(id).get("preco", 1))
	# A honra do Ifrit dá desconto (ou encarece) nas lojas.
	return maxi(1, int(ceil(base * GameState.price_factor() / float(Data.currencies[_shop.moeda].valor))))


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var currency_name := Data.currency_name(_shop.moeda)
	_money.text = "%s: %d" % [currency_name, GameState.money(_shop.moeda)]
	if _selling:
		var sellable := GameState.inventory.keys()
		for id in GameState.storage:
			if not id in sellable:
				sellable.append(id)
		for id in sellable:
			var data := Data.item(id)
			if data.get("tipo") in ["chave", "missao"] or not data.get("vendavel", true):
				continue
			if GameState.spare_count(id) <= 0:
				continue
			var value := maxi(1, _price(id) / 2)
			var b := UiKit.button("%s x%d   vende por %d" % [data.nome, GameState.spare_count(id), value])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.pressed.connect(_sell.bind(id, value))
			_list.add_child(b)
	else:
		for id in _shop.itens:
			var data := Data.item(id)
			var b := UiKit.button("%s   %d %s" % [data.nome, _price(id), currency_name])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = GameState.money(_shop.moeda) < _price(id)
			if data.get("tipo") == "bolsa" and int(data.get("nivel", 0)) <= GameState.bag_level:
				b.disabled = true
				b.text = "%s   (já tem)" % data.nome
			if data.get("tipo") == "montaria" and data.get("montaria", "") in GameState.mounts:
				b.disabled = true
				b.text = "%s   (já tem)" % data.nome
			# Sinal de melhor/pior que o equipamento em uso.
			var delta = GameState.equip_delta(id)
			if delta != null:
				var mark := CompareMark.make(delta, 10.0)
				mark.anchor_left = 1.0
				mark.anchor_right = 1.0
				mark.anchor_top = 0.5
				mark.anchor_bottom = 0.5
				mark.offset_left = -16
				mark.offset_right = -6
				mark.offset_top = -5
				mark.offset_bottom = 5
				b.add_child(mark)
				b.text += "   %s%d" % ["+" if delta > 0 else "", delta] if delta != 0 else "   igual"
			b.pressed.connect(_buy.bind(id))
			b.mouse_entered.connect(func(): _info.text = data.get("descricao", ""))
			_list.add_child(b)


func _buy(id: String) -> void:
	if GameState.spend(_shop.moeda, _price(id)):
		Som.sfx("comprar", -4.0)
		var data := Data.item(id)
		if data.get("tipo") == "montaria":
			GameState.add_mount(data.montaria)
			_info.text = "Agora você tem: %s! Toque em MONTAR fora das cidades fechadas." % Data.mount(data.montaria).nome
		else:
			GameState.add_item(id, 1, false)
			_info.text = "Comprou %s." % data.nome
	_refresh()


func _sell(id: String, value: int) -> void:
	if GameState.remove_item(id):
		GameState.add_money(_shop.moeda, value)
		_info.text = "Vendeu %s." % Data.item(id).nome
	_refresh()
