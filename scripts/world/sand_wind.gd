class_name SandWind
extends CPUParticles2D
## Vento no deserto: grãos de areia e fiapos de poeira atravessando a tela.
## Fica preso à câmera e só aparece em mapas abertos de areia.


func _ready() -> void:
	var view := get_viewport_rect().size
	amount = 70
	lifetime = 2.6
	preprocess = 2.6
	local_coords = false
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(view.x * 0.7, view.y * 0.6)
	position = Vector2(-view.x * 0.35, 0)
	direction = Vector2(1, 0.12)
	spread = 8.0
	gravity = Vector2.ZERO
	initial_velocity_min = 55.0
	initial_velocity_max = 110.0
	scale_amount_min = 1.0
	scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.92, 0.75, 0), Color(1, 0.9, 0.7, 0.55), Color(0.95, 0.82, 0.6, 0.4), Color(0.95, 0.82, 0.6, 0)])
	color_ramp = ramp
	z_index = 50
	# Fiapos de poeira: rastros compridos e transparentes.
	var wisps := CPUParticles2D.new()
	wisps.amount = 6
	wisps.lifetime = 3.5
	wisps.preprocess = 3.5
	wisps.local_coords = false
	wisps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	wisps.emission_rect_extents = emission_rect_extents
	wisps.direction = direction
	wisps.spread = 4.0
	wisps.gravity = Vector2.ZERO
	wisps.initial_velocity_min = 40.0
	wisps.initial_velocity_max = 70.0
	wisps.texture = _wisp_texture()
	var wramp := Gradient.new()
	wramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	wramp.colors = PackedColorArray([Color(1, 0.93, 0.8, 0), Color(1, 0.93, 0.8, 0.18), Color(1, 0.93, 0.8, 0.12), Color(1, 0.93, 0.8, 0)])
	wisps.color_ramp = wramp
	add_child(wisps)


static func _wisp_texture() -> Texture2D:
	var img := Image.create(28, 2, false, Image.FORMAT_RGBA8)
	for x in 28:
		var a := sin(PI * x / 27.0)
		img.set_pixel(x, 0, Color(1, 1, 1, a * 0.7))
		img.set_pixel(x, 1, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


## Mapas abertos com mais areia do que grama.
static func wanted(map_id: String, rows: Array) -> bool:
	if map_id.begins_with("lar_") or map_id in ["casa_mae", "palacio_miraj", "covil_escorpiao", "nascente_miraj",
			"caverna_zazu", "biblioteca_qadim", "fabrica_grifo", "quartel_varek", "trono_cinzento", "navio_pirata"]:
		return false
	var flat := "".join(PackedStringArray(rows))
	return flat.count(".") > flat.count(",") * 1.5 and flat.count(".") > 300
