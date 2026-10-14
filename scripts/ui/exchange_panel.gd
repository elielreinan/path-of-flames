class_name ExchangePanel
extends Control
## Câmbio: troca uma moeda por outra pelo valor base, menos a taxa do cambista.

signal closed

var _from: OptionButton
var _to: OptionButton
var _amount := 10
var _amount_label: Label
var _quote: Label
var _wallet: Label
var _ids: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w := UiKit.window("Câmbio", Vector2(340, 150))
	add_child(w.root)
	w.close.pressed.connect(func(): closed.emit())
	for id in Data.currencies:
		if not id.begins_with("_"):
			_ids.append(id)
	_wallet = UiKit.label("", 9, Color(1, 0.85, 0.3))
	w.box.add_child(_wallet)
	var row := HBoxContainer.new()
	w.box.add_child(row)
	row.add_child(_inline("Dar:"))
	_from = _currency_picker(0)
	row.add_child(_from)
	row.add_child(_inline("Receber:"))
	_to = _currency_picker(1)
	row.add_child(_to)
	var amounts := HBoxContainer.new()
	w.box.add_child(amounts)
	for step in [-10, -1, 1, 10]:
		var b := UiKit.button(("%+d" % step))
		b.pressed.connect(_change.bind(step))
		amounts.add_child(b)
	var all := UiKit.button("Tudo")
	all.pressed.connect(func(): _amount = maxi(1, GameState.money(_selected(_from))); _refresh())
	amounts.add_child(all)
	_amount_label = _inline("")
	amounts.add_child(_amount_label)
	_quote = UiKit.label("", 9, UiKit.MUTED)
	w.box.add_child(_quote)
	var confirm := UiKit.button("Trocar", 10)
	confirm.pressed.connect(_confirm)
	w.box.add_child(confirm)
	_refresh()


func _inline(text: String) -> Label:
	var l := UiKit.label(text, 9)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l


func _currency_picker(selected: int) -> OptionButton:
	var picker := OptionButton.new()
	picker.add_theme_font_size_override("font_size", 9)
	picker.focus_mode = Control.FOCUS_NONE
	for id in _ids:
		picker.add_item(Data.currency_name(id))
	picker.select(mini(selected, _ids.size() - 1))
	picker.item_selected.connect(func(_i): _refresh())
	return picker


func _selected(picker: OptionButton) -> String:
	return _ids[picker.selected]


func _change(step: int) -> void:
	_amount = clampi(_amount + step, 1, maxi(1, GameState.money(_selected(_from))))
	_refresh()


func _refresh() -> void:
	var parts := []
	for id in _ids:
		parts.append("%s: %d" % [Data.currency_name(id), GameState.money(id)])
	_wallet.text = "   ".join(parts)
	_amount_label.text = "  %d" % _amount
	var from := _selected(_from)
	var to := _selected(_to)
	if from == to:
		_quote.text = "Escolha moedas diferentes."
		return
	var received := GameState.exchange_quote(from, to, _amount)
	_quote.text = "%d %s → %d %s (taxa de %d%%)" % [_amount, Data.currency_name(from), received,
		Data.currency_name(to), int(Data.currencies.get("_taxa", 0.1) * 100)]


func _confirm() -> void:
	var from := _selected(_from)
	var to := _selected(_to)
	if from == to:
		return
	var received := GameState.exchange(from, to, _amount)
	if received == 0:
		_quote.text = "Moedas insuficientes ou quantia pequena demais."
	else:
		_quote.text = "Recebeu %d %s." % [received, Data.currency_name(to)]
		_amount = 1
	_wallet.text = ""
	await get_tree().create_timer(1.2, true).timeout
	if is_inside_tree():
		_refresh()
