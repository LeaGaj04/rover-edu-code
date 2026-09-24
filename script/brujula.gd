extends Control

## Brújula de Navegación Espacial para SpidoCode.
## Proporciona orientación cardinal (Norte, Sur, Este, Oeste) acorde al sistema de
## coordenadas 3D del Spid (CharacterBody3D):
##   - Norte: Vector3.FORWARD (-Z) -> Hacia ARRIBA en pantalla
##   - Sur:   Vector3.BACK    (+Z) -> Hacia ABAJO en pantalla
##   - Este:  Vector3.RIGHT   (+X) -> Hacia la DERECHA en pantalla
##   - Oeste: Vector3.LEFT    (-X) -> Hacia la IZQUIERDA en pantalla
##
## Es interactiva y desplazable: el jugador puede hacer clic y arrastrarla para
## ubicarla en cualquier parte de la pantalla, al igual que la consola de Spid.

const DIAMETRO := 112.0
const RADIO := DIAMETRO * 0.5
const MARGEN_PANTALLA := 20.0

# --- Estado de arrastre y UI ---
var arrastrando: bool = false
var offset_arrastre: Vector2 = Vector2.ZERO
var hover: bool = false
var ha_sido_movida_por_usuario: bool = false

# --- Paleta estética inspirada en el proyecto y las referencias ---
const COLOR_SOMBRA        := Color(0.0, 0.0, 0.0, 0.45)
const COLOR_BISEL_EXT     := Color(0.20, 0.23, 0.27, 0.98)
const COLOR_BRONCE        := Color(0.68, 0.52, 0.28, 1.0)
const COLOR_ORO_BRIGHT    := Color(0.92, 0.78, 0.46, 1.0)
const COLOR_ORO_DARK      := Color(0.42, 0.30, 0.15, 1.0)
const COLOR_FONDO_DIAL    := Color(0.02, 0.05, 0.08, 0.94)

const COLOR_RADAR_CYAN    := Color(0.18, 0.85, 0.95, 0.28)
const COLOR_RADAR_SUBTLE  := Color(0.15, 0.70, 0.85, 0.14)

const COLOR_NORTE_LIT     := Color(1.00, 0.80, 0.28, 1.0)
const COLOR_NORTE_SHADE   := Color(0.88, 0.32, 0.08, 1.0)

const COLOR_STEEL_LIT     := Color(0.38, 0.82, 0.94, 0.95)
const COLOR_STEEL_SHADE   := Color(0.12, 0.40, 0.55, 0.95)

const COLOR_DIAG_LIT      := Color(0.40, 0.48, 0.54, 0.75)
const COLOR_DIAG_SHADE    := Color(0.18, 0.24, 0.28, 0.75)

const COLOR_CORE_OUTER    := Color(0.65, 0.50, 0.25, 1.0)
const COLOR_CORE_GLOW     := Color(0.18, 0.95, 0.88, 0.95)
const COLOR_HOVER_GLOW    := Color(0.25, 0.92, 0.85, 0.75)

const COLOR_TXT_NORTE     := Color(1.00, 0.85, 0.35, 1.0)
const COLOR_TXT_CARDINAL  := Color(0.78, 0.92, 1.00, 0.95)
const COLOR_TXT_OUTLINE   := Color(0.01, 0.02, 0.04, 0.95)

var fuente: Font = null


func _ready() -> void:
	custom_minimum_size = Vector2(DIAMETRO, DIAMETRO)
	size = Vector2(DIAMETRO, DIAMETRO)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_MOVE
	tooltip_text = "Brújula de Navegación\n(Haz clic y arrastra para reubicar)"

	# Carga de fuente temática con respaldo automático
	if ResourceLoader.exists("res://assets/fonts/PixelifySans.ttf"):
		fuente = load("res://assets/fonts/PixelifySans.ttf")
	if fuente == null:
		fuente = ThemeDB.fallback_font

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Ubicación inicial en esquina inferior derecha
	call_deferred("_posicionar_inicial")


func _posicionar_inicial() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	position = Vector2(
		vp.x - DIAMETRO - MARGEN_PANTALLA,
		vp.y - DIAMETRO - MARGEN_PANTALLA
	)


func _on_viewport_size_changed() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if not ha_sido_movida_por_usuario:
		_posicionar_inicial()
	else:
		# Si la pantalla cambió de resolución, asegurar que no quede fuera de límites
		var limite := Vector2(
			maxf(MARGEN_PANTALLA, vp.x - size.x - MARGEN_PANTALLA),
			maxf(MARGEN_PANTALLA, vp.y - size.y - MARGEN_PANTALLA)
		)
		position = position.clamp(Vector2(MARGEN_PANTALLA, MARGEN_PANTALLA), limite)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			arrastrando = true
			offset_arrastre = get_viewport().get_mouse_position() - position
			mouse_default_cursor_shape = Control.CURSOR_DRAG
			queue_redraw()
			accept_event()
		else:
			if arrastrando:
				arrastrando = false
				mouse_default_cursor_shape = Control.CURSOR_MOVE
				queue_redraw()
				accept_event()


func _input(event: InputEvent) -> void:
	if arrastrando:
		if event is InputEventMouseMotion:
			_mover_brujula(get_viewport().get_mouse_position() - offset_arrastre)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			arrastrando = false
			mouse_default_cursor_shape = Control.CURSOR_MOVE
			queue_redraw()


func _mover_brujula(nueva_pos: Vector2) -> void:
	ha_sido_movida_por_usuario = true
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var limite := Vector2(
		maxf(MARGEN_PANTALLA, vp.x - size.x - MARGEN_PANTALLA),
		maxf(MARGEN_PANTALLA, vp.y - size.y - MARGEN_PANTALLA)
	)
	position = nueva_pos.clamp(Vector2(MARGEN_PANTALLA, MARGEN_PANTALLA), limite)


func _on_mouse_entered() -> void:
	hover = true
	queue_redraw()


func _on_mouse_exited() -> void:
	hover = false
	queue_redraw()


func _draw() -> void:
	var c := Vector2(RADIO, RADIO)

	# 1. Sombra exterior
	draw_circle(c + Vector2(2.5, 3.5), RADIO - 1.0, COLOR_SOMBRA)

	# 2. Resplandor exterior al interactuar (hover / drag)
	if hover or arrastrando:
		draw_arc(c, RADIO + 1.0, 0.0, TAU, 64, COLOR_HOVER_GLOW, 2.5, true)

	# 3. Bisel exterior metálico
	draw_circle(c, RADIO - 1.5, COLOR_BISEL_EXT)

	# 4. Anillo de bronce / oro grabado
	draw_arc(c, RADIO - 3.5, 0.0, TAU, 64, COLOR_BRONCE, 3.2, true)

	# Reflejo especular superior en el anillo metálico
	draw_arc(c, RADIO - 3.0, -PI * 0.85, -PI * 0.15, 32, COLOR_ORO_BRIGHT, 1.4, true)
	draw_arc(c, RADIO - 4.0, PI * 0.15, PI * 0.85, 32, COLOR_ORO_DARK, 1.2, true)

	# Ranura interior del marco
	draw_arc(c, RADIO - 6.0, 0.0, TAU, 64, Color(0.06, 0.08, 0.10, 0.9), 1.5, true)

	# 5. Esfera interior (dial espacial)
	draw_circle(c, RADIO - 7.0, COLOR_FONDO_DIAL)

	# Pista circular de radar
	draw_arc(c, RADIO * 0.70, 0.0, TAU, 64, COLOR_RADAR_CYAN, 1.0, true)
	draw_arc(c, RADIO * 0.44, 0.0, TAU, 48, COLOR_RADAR_SUBTLE, 0.8, true)

	# 6. Muescas perimetrales (16 divisiones)
	for i in range(16):
		var angulo: float = i * (TAU / 16.0)
		var es_cardinal: bool = (i % 4 == 0)
		var r_inicio: float = RADIO - (12.0 if es_cardinal else 10.0)
		var r_fin: float = RADIO - 7.5
		var dir := Vector2(cos(angulo), sin(angulo))
		var col: Color = COLOR_ORO_BRIGHT if es_cardinal else Color(0.30, 0.60, 0.70, 0.45)
		var grosor: float = 1.8 if es_cardinal else 1.0
		draw_line(c + dir * r_inicio, c + dir * r_fin, col, grosor)

	# 7. Estrella secundaria de 4 puntas diagonales (NE, SE, SO, NO)
	var diag_len := RADIO * 0.48
	var diag_width := 5.0
	_dibujar_punta_facetada(c, Vector2( 0.7071, -0.7071), diag_len, diag_width, COLOR_DIAG_LIT, COLOR_DIAG_SHADE)
	_dibujar_punta_facetada(c, Vector2( 0.7071,  0.7071), diag_len, diag_width, COLOR_DIAG_LIT, COLOR_DIAG_SHADE)
	_dibujar_punta_facetada(c, Vector2(-0.7071,  0.7071), diag_len, diag_width, COLOR_DIAG_LIT, COLOR_DIAG_SHADE)
	_dibujar_punta_facetada(c, Vector2(-0.7071, -0.7071), diag_len, diag_width, COLOR_DIAG_LIT, COLOR_DIAG_SHADE)

	# 8. Puntas cardinales principales (Sur, Este, Oeste)
	var card_len := RADIO * 0.58
	var card_width := 6.5
	_dibujar_punta_facetada(c, Vector2.DOWN,  card_len, card_width, COLOR_STEEL_LIT, COLOR_STEEL_SHADE)
	_dibujar_punta_facetada(c, Vector2.RIGHT, card_len, card_width, COLOR_STEEL_LIT, COLOR_STEEL_SHADE)
	_dibujar_punta_facetada(c, Vector2.LEFT,  card_len, card_width, COLOR_STEEL_LIT, COLOR_STEEL_SHADE)

	# 9. Punta Norte prominente (hacia arriba, dorada/naranja luminosa)
	var norte_len := RADIO * 0.68
	var norte_width := 7.5
	_dibujar_punta_facetada(c, Vector2.UP, norte_len, norte_width, COLOR_NORTE_LIT, COLOR_NORTE_SHADE)

	# Brillo central en la punta Norte
	draw_line(c, c + Vector2(0, -norte_len), Color(1.0, 1.0, 0.8, 0.8), 1.0)

	# 10. Reactor / Gema central
	draw_circle(c, 8.5, COLOR_CORE_OUTER)
	draw_arc(c, 8.5, 0.0, TAU, 32, COLOR_ORO_BRIGHT, 1.0, true)
	draw_circle(c, 6.5, Color(0.04, 0.08, 0.12))
	draw_circle(c, 5.0, COLOR_CORE_GLOW)
	draw_circle(c + Vector2(-1.4, -1.4), 1.8, Color(0.9, 1.0, 1.0, 0.95)) # Destello especular

	# 11. Letras Cardinales (N, S, E, O)
	var font_to_use: Font = fuente if fuente != null else ThemeDB.fallback_font
	var dist_letra := RADIO * 0.74

	_dibujar_texto_centrado(font_to_use, c + Vector2(0.0, -dist_letra + 1.0), "N", 14, COLOR_TXT_NORTE)
	_dibujar_texto_centrado(font_to_use, c + Vector2(0.0,  dist_letra + 1.0), "S", 13, COLOR_TXT_CARDINAL)
	_dibujar_texto_centrado(font_to_use, c + Vector2( dist_letra,  0.0),    "E", 13, COLOR_TXT_CARDINAL)
	_dibujar_texto_centrado(font_to_use, c + Vector2(-dist_letra,  0.0),    "O", 13, COLOR_TXT_CARDINAL)


## Dibuja una punta de brújula con dos triángulos facetados (luz y sombra)
## para lograr el efecto 3D metálico visto en las referencias.
func _dibujar_punta_facetada(center: Vector2, dir: Vector2, length: float,
		half_width: float, col_lit: Color, col_shade: Color) -> void:
	var tip := center + dir * length
	var perp := Vector2(-dir.y, dir.x) * half_width
	var base := center + dir * (length * 0.15)

	# Lado izquierdo (iluminado)
	var poly_lit := PackedVector2Array([tip, base, base - perp])
	draw_colored_polygon(poly_lit, col_lit)

	# Lado derecho (en sombra)
	var poly_shade := PackedVector2Array([tip, base + perp, base])
	draw_colored_polygon(poly_shade, col_shade)


## Dibuja un texto centrado en `pos` con contorno oscuro para legibilidad garantizada.
func _dibujar_texto_centrado(f: Font, pos: Vector2, txt: String, font_size: int, col: Color) -> void:
	var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var base_pos := pos - Vector2(sz.x * 0.5, -sz.y * 0.32)

	# Contorno manual de 4 direcciones para nitidez
	for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_string(f, base_pos + offset, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_TXT_OUTLINE)

	# Texto principal
	draw_string(f, base_pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
