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


## Peça 9-slice da arte (assets/ui), ou null se o arquivo não existir.
static func art_box(path: String, margins: Array, content := -1.0, tile := false) -> StyleBoxTexture:
	var full := "res://assets/ui/" + path
	if not ResourceLoader.exists(full):
		return null
	var style := StyleBoxTexture.new()
	style.texture = load(full)
	style.texture_margin_left = margins[0]
	style.texture_margin_right = margins[1]
	style.texture_margin_top = margins[2]
	style.texture_margin_bottom = margins[3]
	if tile:
		style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	if content >= 0.0:
		style.set_content_margin_all(content)
	return style


## Painel de madeira (menus, pausa, loja); "bolsa" = couro costurado; "papel" = texto escuro.
static func panel_box(kind := "menu") -> StyleBox:
	var m := 9 if kind == "bolsa" else 8
	var style := art_box("paineis/painel_%s.png" % kind, [m, m, m, m], 8.0, kind == "bolsa")
	return style if style else panel_style()


## Aba ou opção selecionada.
static func selected_style() -> StyleBox:
	var style := art_box("botoes/menu_foco.png", [4, 4, 4, 6])
	if style == null:
		return panel_style(Color(0.85, 0.5, 0.15))
	_button_margins(style, false)
	return style


static func panel(kind := "menu") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_box(kind))
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
	var art := art_box("botoes/menu_normal.png", [4, 4, 4, 6])
	if art:
		# Botão de madeira clara da arte: texto escuro, desce 2 px quando apertado.
		for state in ["normal", "hover", "pressed", "disabled"]:
			var file: String = {"normal": "normal", "hover": "normal", "pressed": "pressionado", "disabled": "desabilitado"}[state]
			var style := art_box("botoes/menu_%s.png" % file, [4, 4, 4, 6])
			_button_margins(style, state == "pressed")
			b.add_theme_stylebox_override(state, style)
		var ink := Color("#3e2731")
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(key, ink)
		b.add_theme_color_override("font_disabled_color", Color("#5a6988"))
		return b
	b.add_theme_stylebox_override("normal", button_style(Color(0.42, 0.24, 0.11)))
	b.add_theme_stylebox_override("hover", button_style(Color(0.52, 0.3, 0.13)))
	b.add_theme_stylebox_override("pressed", button_style(Color(0.3, 0.17, 0.08), true))
	b.add_theme_stylebox_override("disabled", button_style(Color(0.22, 0.19, 0.17)))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 0.92))
	b.add_theme_color_override("font_pressed_color", ACCENT)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	b.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	b.add_theme_constant_override("outline_size", 2)
	return b


## Fundo normal dos botões (para devolver a aba que deixou de estar selecionada).
static func button_box() -> StyleBox:
	var style := art_box("botoes/menu_normal.png", [4, 4, 4, 6])
	if style == null:
		return button_style(Color(0.42, 0.24, 0.11))
	_button_margins(style, false)
	return style


static func _button_margins(style: StyleBox, pressed: bool) -> void:
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4 if pressed else 2
	style.content_margin_bottom = 4 if pressed else 6


## Botão em relevo: borda dourada, luz em cima e "degrau" escuro embaixo; apertado, afunda.
static func button_style(bg: Color, pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = BORDER.darkened(0.15)
	style.set_border_width_all(1)
	style.border_width_top = 1 if pressed else 2
	style.set_corner_radius_all(3)
	style.anti_aliasing = false
	style.shadow_color = Color(0.06, 0.03, 0.02, 0.95)
	style.shadow_size = 0 if pressed else 1
	style.shadow_offset = Vector2(0, 0 if pressed else 2)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 4 if pressed else 3
	style.content_margin_bottom = 2 if pressed else 3
	return style


## Painel centralizado de tela cheia com título e botão de fechar.
static func window(title: String, size := Vector2(380, 220), kind := "menu") -> Dictionary:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var p := panel(kind)
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
	# Botão de fechar quadrado com X (arte), ou "Fechar" escrito se faltar a arte.
	var close: Control = IconButton.make("fechar", 20) if ResourceLoader.exists("res://assets/ui/botoes/quad_fechar_normal.png") else button("Fechar")
	header.add_child(close)
	return {"root": root, "box": box, "close": close, "header": header}
