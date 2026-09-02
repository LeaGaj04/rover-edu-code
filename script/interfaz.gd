extends CanvasLayer

@onready var panel_codigo: Panel = $PanelCodigo
@onready var barra_codigo: Panel = $PanelCodigo/BarraTitulo
@onready var contenido_codigo: Control = $PanelCodigo/Contenido
@onready var boton_minimizar: Button = $PanelCodigo/BarraTitulo/BotonMinimizar
@onready var caja_codigo: TextEdit = $PanelCodigo/Contenido/TextEdit
@export var mi_rover : CharacterBody3D

const ALTO_PANEL_CODIGO: float = 276.0
const ALTO_PANEL_MINIMIZADO: float = 60.0
const MARGEN_PANTALLA: float = 8.0
const TAMANO_MINIMO_PANEL: Vector2 = Vector2(420.0, 220.0)

var arrastrando_panel: bool = false
var offset_arrastre: Vector2 = Vector2.ZERO
var redimensionando_panel: bool = false
var esquina_redimension: Vector2 = Vector2.ZERO
var mouse_inicio_redimension: Vector2 = Vector2.ZERO
var posicion_inicio_redimension: Vector2 = Vector2.ZERO
var tamano_inicio_redimension: Vector2 = Vector2.ZERO
var alto_panel_expandido: float = ALTO_PANEL_CODIGO

# --- VARIABLES DE RECURSOS ---
const CAPACIDAD_ROVER : int = 10
const CAPACIDAD_NAVE : int = 100

var minerales_nave : int = 0
var minerales_rover : int = 0

# --- REFERENCIAS A LOS CONTADORES VISUALES ---
@export var label_nave : Label
@export var label_rover : Label

# --- REFERENCIAS A LA TIENDA ---
@onready var panel_tienda = $PanelTienda
@onready var boton_tienda = $ContenedorTienda/BotonTienda
@onready var boton_while = $PanelTienda/LienzoArbol/ButtonWhile
@onready var boton_for = $PanelTienda/LienzoArbol/ButtonFor
@onready var boton_if = $PanelTienda/LienzoArbol/ButtonIf
@onready var boton_expansion = $PanelTienda/LienzoArbol/ButtonExpansion1

const PRECIOS = {
	"while": 15,
	"for": 30,
	"mapa": 30
}

func _ready() -> void:
	barra_codigo.gui_input.connect(_on_barra_codigo_gui_input)
	$PanelCodigo/EsquinaSuperiorIzquierda.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(-1, -1)))
	$PanelCodigo/EsquinaSuperiorDerecha.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(1, -1)))
	$PanelCodigo/EsquinaInferiorIzquierda.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(-1, 1)))
	$PanelCodigo/EsquinaInferiorDerecha.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(1, 1)))
	get_viewport().size_changed.connect(_mantener_panel_en_pantalla)

	# Oculta el árbol apenas arranca el juego
	if panel_tienda != null:
		panel_tienda.hide()
	
	# Actualizamos los textos al iniciar
	actualizar_contadores()
	actualizar_mejoras_visual()
	# Conectamos la señal del rover a una nueva función de la interfaz
	if mi_rover != null:
		mi_rover.mineral_recolectado.connect(_sumar_minerales_rover)


func _on_boton_tienda_pressed() -> void:
	panel_tienda.show()
	boton_tienda.hide()


func _input(event: InputEvent) -> void:
	if redimensionando_panel:
		if event is InputEventMouseMotion:
			_redimensionar_panel_codigo(get_viewport().get_mouse_position())
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			redimensionando_panel = false

	if arrastrando_panel:
		if event is InputEventMouseMotion:
			_mover_panel_codigo(get_viewport().get_mouse_position() - offset_arrastre)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			arrastrando_panel = false

	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_on_button_pressed()


func _on_barra_codigo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		arrastrando_panel = event.pressed
		if arrastrando_panel:
			offset_arrastre = get_viewport().get_mouse_position() - panel_codigo.position
		barra_codigo.accept_event()


func _on_esquina_codigo_gui_input(event: InputEvent, esquina: Vector2) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		redimensionando_panel = event.pressed
		if redimensionando_panel:
			arrastrando_panel = false
			esquina_redimension = esquina
			mouse_inicio_redimension = get_viewport().get_mouse_position()
			posicion_inicio_redimension = panel_codigo.position
			tamano_inicio_redimension = panel_codigo.size
		get_viewport().set_input_as_handled()


func _redimensionar_panel_codigo(mouse_actual: Vector2) -> void:
	var delta: Vector2 = mouse_actual - mouse_inicio_redimension
	var nueva_posicion: Vector2 = posicion_inicio_redimension
	var nuevo_tamano: Vector2 = tamano_inicio_redimension
	var pantalla: Vector2 = get_viewport().get_visible_rect().size

	if esquina_redimension.x > 0:
		nuevo_tamano.x = clampf(tamano_inicio_redimension.x + delta.x, TAMANO_MINIMO_PANEL.x, pantalla.x - posicion_inicio_redimension.x - MARGEN_PANTALLA)
	else:
		nuevo_tamano.x = clampf(tamano_inicio_redimension.x - delta.x, TAMANO_MINIMO_PANEL.x, posicion_inicio_redimension.x + tamano_inicio_redimension.x - MARGEN_PANTALLA)
		nueva_posicion.x = posicion_inicio_redimension.x + tamano_inicio_redimension.x - nuevo_tamano.x

	if esquina_redimension.y > 0:
		nuevo_tamano.y = clampf(tamano_inicio_redimension.y + delta.y, TAMANO_MINIMO_PANEL.y, pantalla.y - posicion_inicio_redimension.y - MARGEN_PANTALLA)
	else:
		nuevo_tamano.y = clampf(tamano_inicio_redimension.y - delta.y, TAMANO_MINIMO_PANEL.y, posicion_inicio_redimension.y + tamano_inicio_redimension.y - MARGEN_PANTALLA)
		nueva_posicion.y = posicion_inicio_redimension.y + tamano_inicio_redimension.y - nuevo_tamano.y

	panel_codigo.position = nueva_posicion
	panel_codigo.size = nuevo_tamano


func _mover_panel_codigo(nueva_posicion: Vector2) -> void:
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var limite: Vector2 = Vector2(
		maxf(MARGEN_PANTALLA, pantalla.x - panel_codigo.size.x - MARGEN_PANTALLA),
		maxf(MARGEN_PANTALLA, pantalla.y - panel_codigo.size.y - MARGEN_PANTALLA)
	)
	panel_codigo.position = nueva_posicion.clamp(
		Vector2(MARGEN_PANTALLA, MARGEN_PANTALLA),
		limite
	)


func _mantener_panel_en_pantalla() -> void:
	_mover_panel_codigo(panel_codigo.position)


func _on_boton_minimizar_pressed() -> void:
	if contenido_codigo.visible:
		alto_panel_expandido = panel_codigo.size.y
	contenido_codigo.visible = not contenido_codigo.visible
	panel_codigo.size.y = alto_panel_expandido if contenido_codigo.visible else ALTO_PANEL_MINIMIZADO
	for esquina in [
		$PanelCodigo/EsquinaSuperiorIzquierda,
		$PanelCodigo/EsquinaSuperiorDerecha,
		$PanelCodigo/EsquinaInferiorIzquierda,
		$PanelCodigo/EsquinaInferiorDerecha
	]:
		esquina.visible = contenido_codigo.visible
	boton_minimizar.text = "_" if contenido_codigo.visible else "+"
	boton_minimizar.tooltip_text = "Minimizar la consola" if contenido_codigo.visible else "Abrir la consola"
	_mantener_panel_en_pantalla()


func _on_button_pressed() -> void:
	# Validamos todas las mejoras antes de procesar cualquier linea.
	# Si hay sintaxis no adquirida, se aborta la ejecucion completa.
	if not GestorSintaxis.validar_codigo(caja_codigo.text):
		return

	var lineas = caja_codigo.text.split("\n")
	
	for linea in lineas:
		linea = linea.strip_edges()
		if linea == "":
			continue # Salta líneas vacías
			
		# Verificación básica
		if not linea.begins_with("rover."):
			print("Error de Sintaxis A.D.A en '", linea, "': Debe empezar con 'rover.'")
			continue
			
		# Ubicamos los límites de la sintaxis: rover.comando(pasos)
		var pos_punto = linea.find(".")
		var pos_par_izq = linea.find("(")
		var pos_par_der = linea.rfind(")")
		
		if pos_punto == -1 or pos_par_izq == -1 or pos_par_der == -1:
			print("Error de Sintaxis A.D.A en '", linea, "': Falta punto o paréntesis.")
			continue
			
		# Extraemos el comando y lo que está dentro de los paréntesis
		var comando = linea.substr(pos_punto + 1, pos_par_izq - pos_punto - 1).strip_edges()
		var dentro_parentesis = linea.substr(pos_par_izq + 1, pos_par_der - pos_par_izq - 1).strip_edges()
		
		var pasos = 1 # Pasos por defecto (ej: rover.sur())
		
		# Si hay un número válido dentro de (), lo convertimos a entero
		if dentro_parentesis.is_valid_int():
			pasos = int(dentro_parentesis)
		
		await ejecutar_movimiento_rover(comando, pasos)


func ejecutar_movimiento_rover(comando: String, pasos: int) -> void:
	if mi_rover == null:
		print("Error: El Rover no está asignado en el Inspector.")
		return
		
	print("Ejecutando: ", comando, " (", pasos, " pasos)")
	
	if comando == "norte":
		await mi_rover.norte(pasos)
	elif comando == "sur":
		await mi_rover.sur(pasos)
	elif comando == "este":
		await mi_rover.este(pasos)
	elif comando == "oeste":
		await mi_rover.oeste(pasos)
	elif comando == "minar":
		if minerales_rover >= CAPACIDAD_ROVER:
			print("Inventario lleno: el Rover solo puede transportar ", CAPACIDAD_ROVER, " minerales.")
			return
		await mi_rover.minar()
	elif comando == "transferir":
		procesar_transferencia()
	else:
		print("Error A.D.A: El rover no conoce el comando '", comando, "'")


func _on_boton_cerrar_pressed() -> void:
	# Ocultamos el panel directamente
	panel_tienda.hide()
	
	# Restauramos el botón principal para poder volver a abrir la tienda.
	boton_tienda.text = "MEJORAS"
	boton_tienda.show()
	
func actualizar_contadores() -> void:
	if label_nave != null:
		#Nave
		label_nave.text = ": " + str(minerales_nave) + "/" + str(CAPACIDAD_NAVE)
	if label_rover != null:
		#Rover
		label_rover.text = ": " + str(minerales_rover) + "/" + str(CAPACIDAD_ROVER)


# Aplica solamente el estado persistente que corresponde a la interfaz.
func aplicar_progreso(progress: Dictionary) -> void:
	minerales_nave = maxi(0, int(progress.get("minerals_ship", 0)))
	minerales_rover = maxi(0, int(progress.get("minerals_rover", 0)))
	actualizar_contadores()
	actualizar_mejoras_visual()


func get_progress_state() -> Dictionary:
	var mundo := get_parent()
	return {
		"minerals_ship": minerales_nave,
		"minerals_rover": minerales_rover,
		"map_tier": mundo.get_map_tier() if mundo != null else 0,
		"unlocked_syntax": GestorSintaxis.get_sintaxis_desbloqueada(),
	}


func _solicitar_guardado_progreso() -> void:
	ProgressService.save_progress(get_progress_state())


func actualizar_mejoras_visual() -> void:
	if boton_while != null:
		boton_while.disabled = GestorSintaxis.esta_desbloqueada("while")
	if boton_for != null:
		boton_for.disabled = GestorSintaxis.esta_desbloqueada("for")
	if boton_if != null:
		boton_if.disabled = GestorSintaxis.esta_desbloqueada("if")
	if boton_expansion != null:
		var mundo := get_parent()
		boton_expansion.disabled = mundo != null and mundo.mapa_3x3_desbloqueado

func intentar_compra(item_id: String, boton: Button, linea_conectora: CanvasItem) -> void:
	# 1. Verificar si ya se compró previamente
	if GestorSintaxis.esta_desbloqueada(item_id):
		print("El ítem ya está desbloqueado.")
		return
		
	# 2. Obtener el costo
	var costo = PRECIOS[item_id]
	
	# 3. Validar saldo
	if minerales_nave >= costo:
		minerales_nave -= costo
		actualizar_contadores()
		
		# 4. Desbloquear en el backend
		GestorSintaxis.desbloquear_sintaxis(item_id)
		
		# 5. Feedback visual en el árbol
		boton.disabled = true
		if linea_conectora != null:
			linea_conectora.modulate = Color(1.0, 0.84, 0.0) 
			
		print(item_id + " adquirido exitosamente.")
		_solicitar_guardado_progreso()
	else:
		print("Minerales insuficientes para comprar: " + item_id)
		
func _sumar_minerales_rover(cantidad: int) -> void:
	minerales_rover = mini(minerales_rover + cantidad, CAPACIDAD_ROVER)
	actualizar_contadores()
	_solicitar_guardado_progreso()
	
func procesar_transferencia() -> void:
	if mi_rover == null:
		print("Error: El Rover no está asignado.")
		return

	if minerales_rover == 0:
		print("El Rover no tiene minerales para transferir.")
		return

	if minerales_nave >= CAPACIDAD_NAVE:
		print("La Nave está llena. Capacidad máxima: ", CAPACIDAD_NAVE)
		return

	var mundo := get_parent()

	if mundo == null or not mundo.has_method("rover_esta_en_casilla_transferencia"):
		print("Error: No se pudo comprobar la casilla de transferencia.")
		return

	if not mundo.rover_esta_en_casilla_transferencia(mi_rover):
		print("Transferencia rechazada: lleva el Rover a la casilla inicial.")
		return

	var espacio_disponible := CAPACIDAD_NAVE - minerales_nave
	var cantidad_transferida := mini(minerales_rover, espacio_disponible)

	print(
		"Transferencia completada: ",
		cantidad_transferida,
		" minerales enviados a la Nave."
	)

	minerales_nave += cantidad_transferida
	minerales_rover -= cantidad_transferida

	actualizar_contadores()
	_solicitar_guardado_progreso()
		
func _on_button_while_pressed() -> void:
	intentar_compra("while", boton_while, null)

func _on_button_for_pressed() -> void:
	intentar_compra("for", boton_for, null)

func _on_button_expansion_1_pressed() -> void:
	var mundo = get_parent()
	var costo = PRECIOS["mapa"]

	if mundo.mapa_3x3_desbloqueado:
		print("El Mapa 1 ya está desbloqueado.")
		return

	if minerales_nave < costo:
		print("Minerales insuficientes en la Nave. Mapa 1 cuesta ", costo, " minerales.")
		return

	if mundo.expandir_mapa_3x3():
		minerales_nave -= costo
		actualizar_contadores()
		boton_expansion.disabled = true
		_solicitar_guardado_progreso()


func _on_button_expansion_2_pressed() -> void:
	# La segunda expansión queda reservada para una implementación futura.
	print("EX Mapa 2 todavía no está disponible.")
	
