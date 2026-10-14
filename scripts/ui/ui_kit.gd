class_name UiKit
## Funções para montar a interface em código com o mesmo visual.

const BG := Color(0.12, 0.08, 0.06, 0.94)
const BORDER := Color(0.85, 0.6, 0.25)
const TEXT := Color(1, 0.95, 0.85)
const ACCENT := Color(1, 0.8, 0.3)
const MUTED := Color(0.75, 0.68, 0.6)


static func panel_style(bg := BG) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style())
	return p


static func label(text := "", size := 9, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, size := 9) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	var normal := panel_style(Color(0.3, 0.18, 0.1))
	normal.set_content_margin_all(3)
	var hover := panel_style(Color(0.45, 0.27, 0.12))
	hover.set_content_margin_all(3)
	var disabled := panel_style(Color(0.2, 0.17, 0.15))
	disabled.set_content_margin_all(3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", TEXT)
	return b


## Painel centralizado de tela cheia com título e botão de fechar.
static func window(title: String, size := Vector2(380, 220)) -> Dictionary:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var p := panel()
	p.anchor_left = 0.5
	p.anchor_right = 0.5
	p.anchor_top = 0.5
	p.anchor_bottom = 0.5
	p.offset_left = -size.x / 2.0
	p.offset_right = size.x / 2.0
	p.offset_top = -size.y / 2.0
	p.offset_bottom = size.y / 2.0
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(p)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	p.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var t := label(title, 12, ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(t)
	var close := button("Fechar")
	header.add_child(close)
	return {"root": root, "box": box, "close": close, "header": header}
