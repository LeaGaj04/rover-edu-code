extends CanvasLayer

@onready var panel_codigo: Panel = $PanelCodigo
@onready var barra_codigo: Panel = $PanelCodigo/BarraTitulo
@onready var contenido_codigo: Control = $PanelCodigo/Contenido
@onready var boton_minimizar: Button = $PanelCodigo/BarraTitulo/BotonMinimizar
@onready var caja_codigo: TextEdit = $PanelCodigo/Contenido/TextEdit
@onready var boton_ejecutar: Button = $PanelCodigo/Contenido/Button
@onready var transmision_ada = $TransmisionADA
@onready var panel_mision: Panel = $PanelMision
@onready var label_mision: Label = $PanelMision/Nombre
@onready var label_objetivo_mision: Label = $PanelMision/Objetivo
@onready var label_estado_mision: Label = $PanelMision/Estado
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
var posicion_panel_mision: Vector2

# --- VARIABLES DE RECURSOS ---
const CAPACIDAD_ROVER : int = 10
const CAPACIDAD_NAVE : int = 100

var minerales_nave : int = 0
var minerales_rover : int = 0

# --- REFERENCIAS A LOS CONTADORES VISUALES ---
@export var label_nave : Label
@export var label_rover : Label

# Mejoras
@onready var panel_tienda = $PanelTienda
@onready var boton_tienda = $ContenedorTienda/BotonTienda
@onready var panel_archivo = $ArchivoADA
@onready var boton_archivo = $ContenedorTienda/BotonArchivo
@onready var boton_while: Button = $PanelTienda/LienzoArbol/ButtonWhile
@onready var boton_for: Button = $PanelTienda/LienzoArbol/ButtonFor
@onready var boton_if: Button = $PanelTienda/LienzoArbol/ButtonIf
@onready var boton_expansion: Button = $PanelTienda/LienzoArbol/ButtonExpansion1
@onready var boton_expansion_2: Button = $PanelTienda/LienzoArbol/ButtonExpansion2
@onready var boton_expansion_3: Button = $PanelTienda/LienzoArbol/ButtonExpansion3
@onready var boton_mineria: Button = $PanelTienda/LienzoArbol/ButtonMineria

@onready var linea_prog_1: Line2D = $PanelTienda/LienzoArbol/LineaProg1
@onready var linea_prog_2: Line2D = $PanelTienda/LienzoArbol/LineaProg2
@onready var linea_prog_3: Line2D = $PanelTienda/LienzoArbol/LineaProg3
@onready var linea_terr_1: Line2D = $PanelTienda/LienzoArbol/LineaTerr1
@onready var linea_terr_2: Line2D = $PanelTienda/LienzoArbol/LineaTerr2
@onready var linea_terr_3: Line2D = $PanelTienda/LienzoArbol/LineaTerr3
@onready var linea_hard_1: Line2D = $PanelTienda/LienzoArbol/LineaHard1

var mineria_rapida_desbloqueada: bool = false

const PRECIOS = {
	"while": 15,
	"for": 30,
	"mapa": 1,
	"casillas_extra": 10,
	"mapa_3x3": 20,
	"if": 10,
	"mineria_rapida": 15
}

func _ready() -> void:
	barra_codigo.gui_input.connect(_on_barra_codigo_gui_input)
	$PanelCodigo/EsquinaSuperiorIzquierda.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(-1, -1)))
	$PanelCodigo/EsquinaSuperiorDerecha.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(1, -1)))
	$PanelCodigo/EsquinaInferiorIzquierda.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(-1, 1)))
	$PanelCodigo/EsquinaInferiorDerecha.gui_input.connect(_on_esquina_codigo_gui_input.bind(Vector2(1, 1)))
	CodeExecutor.linea_iniciada.connect(_on_linea_iniciada)
	CodeExecutor.error_detectado.connect(_on_error_detectado)
	CodeExecutor.ejecucion_finalizada.connect(_on_ejecucion_finalizada)
	CodeExecutor.progreso_actualizado.connect(_on_progreso_ejecucion)
	MissionService.objetivo_actualizado.connect(_on_objetivo_actualizado)
	MissionService.mision_completada.connect(_on_mision_completada)
	MissionService.conocimiento_desbloqueado.connect(_on_conocimiento_desbloqueado)
	actualizar_panel_mision()
	posicion_panel_mision = panel_mision.position
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
	if panel_archivo != null:
		panel_archivo.cerrado.connect(_on_archivo_cerrado)


func _on_boton_tienda_pressed() -> void:
	actualizar_mejoras_visual()
	panel_tienda.show()
	boton_tienda.hide()
	if boton_archivo != null:
		boton_archivo.hide()
	if panel_codigo != null:
		panel_codigo.hide()


func _on_boton_archivo_pressed() -> void:
	if panel_archivo != null:
		panel_archivo.abrir()
		boton_tienda.hide()
		if boton_archivo != null:
			boton_archivo.hide()
		if panel_codigo != null:
			panel_codigo.hide()


func _on_archivo_cerrado() -> void:
	boton_tienda.show()
	if boton_archivo != null:
		boton_archivo.show()
	if panel_codigo != null:
		panel_codigo.show()


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
	if CodeExecutor.ejecutando:
		CodeExecutor.detener_ejecucion()
		boton_ejecutar.text = "Deteniendo..."
		return

	boton_ejecutar.text = "Detener"

	var resultado: Dictionary = await CodeExecutor.ejecutar_codigo(
		caja_codigo.text,
		ejecutar_movimiento_rover,
		evaluar_condicion_rover
	)

	boton_ejecutar.text = "Ejecutar"

	if resultado["success"]:
		print("Programa completado correctamente.")
	else:
		print("Error A.D.A: ", resultado["error_message"])


func ejecutar_movimiento_rover(
	comando: String,
	pasos: int
) -> Dictionary:
	if mi_rover == null:
		return _crear_error_comando(
			"ejecucion",
			"El rover no está asignado en el Inspector."
		)

	print(
		"Ejecutando: ",
		comando,
		" (",
		pasos,
		" pasos)"
	)

	if comando == "norte":
		return await mi_rover.norte(pasos)

	if comando == "sur":
		return await mi_rover.sur(pasos)

	if comando == "este":
		return await mi_rover.este(pasos)

	if comando == "oeste":
		return await mi_rover.oeste(pasos)

	if comando == "minar":
		if minerales_rover >= CAPACIDAD_ROVER:
			return _crear_error_comando(
				"ejecucion",
				"El inventario del rover está lleno."
			)

		return await mi_rover.minar()

	if comando == "transferir":
		return procesar_transferencia()

	return _crear_error_comando(
		"ejecucion",
		"El rover no conoce el comando '" + comando + "'."
	)

func evaluar_condicion_rover(condicion: String) -> bool:
	if mi_rover == null:
		return false
	if condicion in ["True", "true"]:
		return true
	if condicion in ["False", "false"]:
		return false
	if condicion in ["rover.hay_mineral()", "hay_mineral()"]:
		return mi_rover.hay_mineral()
	if condicion in ["rover.tiene_espacio()", "tiene_espacio()"]:
		return minerales_rover < CAPACIDAD_ROVER
	if condicion in ["rover.en_base()", "en_base()"]:
		var mundo = get_parent()
		if mundo != null and mundo.has_method("rover_esta_en_casilla_transferencia"):
			return mundo.rover_esta_en_casilla_transferencia(mi_rover)
		return false
	return false

func _on_boton_cerrar_pressed() -> void:
	# Ocultamos el panel directamente
	panel_tienda.hide()
	
	# Restauramos el botón principal para poder volver a abrir la tienda.
	boton_tienda.text = "MEJORAS"
	boton_tienda.show()
	if boton_archivo != null:
		boton_archivo.show()
	if panel_codigo != null:
		panel_codigo.show()
	
func actualizar_contadores() -> void:
	if label_nave != null:
		#Nave
		label_nave.text = ": " + str(minerales_nave) + "/" + str(CAPACIDAD_NAVE)
	if label_rover != null:
		#Rover
		label_rover.text = ": " + str(minerales_rover) + "/" + str(CAPACIDAD_ROVER)


# Aplica solamente el estado persistente que corresponde a la interfaz.
func aplicar_progreso(progress: Dictionary) -> void:
	MissionService.aplicar_progreso(progress)

	minerales_nave = maxi(
		0,
		int(progress.get("minerals_ship", 0))
	)

	minerales_rover = maxi(
		0,
		int(progress.get("minerals_rover", 0))
	)

	var hardware = progress.get("hardware_upgrades", {})
	if typeof(hardware) == TYPE_DICTIONARY and int(hardware.get("drill_speed", 0)) > 0:
		mineria_rapida_desbloqueada = true
		if mi_rover != null:
			mi_rover.tiempo_minado = 1.0

	actualizar_contadores()
	actualizar_mejoras_visual()
	_mostrar_mensaje_inicial_ada()


func get_progress_state() -> Dictionary:
	var mundo := get_parent()

	return {
		"minerals_ship": minerales_nave,
		"minerals_rover": minerales_rover,
		"map_tier": mundo.get_map_tier() if mundo != null else 0,
		"unlocked_syntax": GestorSintaxis.get_sintaxis_desbloqueada(),
		"current_mission_id": MissionService.objective_id,
		"completed_missions": MissionService.get_completed_missions(),
		"unlocked_knowledge": MissionService.get_unlocked_knowledge(),
		"hardware_upgrades": {
			"drill_speed": 1 if mineria_rapida_desbloqueada else 0
		}
	}


func _solicitar_guardado_progreso() -> void:
	ProgressService.save_progress(get_progress_state())


func actualizar_mejoras_visual() -> void:
	var mundo := get_parent()
	var while_on := GestorSintaxis.esta_desbloqueada("while")
	var for_on := GestorSintaxis.esta_desbloqueada("for")
	var if_on := GestorSintaxis.esta_desbloqueada("if")

	var exp1_on: bool = mundo != null and bool(mundo.corredor_1x3_desbloqueado)
	var exp2_on: bool = mundo != null and bool(mundo.casillas_extra_desbloqueadas)
	var exp3_on: bool = mundo != null and bool(mundo.mapa_3x3_desbloqueado)

	if boton_while != null:
		boton_while.disabled = while_on
		boton_while.text = "[ BUCLE WHILE ]\nDESBLOQUEADO" if while_on else "[ BUCLE WHILE ]\n15 MINERALES"
	if boton_for != null:
		boton_for.disabled = for_on or not while_on
		boton_for.text = "[ BUCLE FOR ]\nDESBLOQUEADO" if for_on else ("[ BUCLE FOR ]\n30 MINERALES" if while_on else "[ BUCLE FOR ]\nBLOQUEADO")
	if boton_if != null:
		boton_if.disabled = if_on or not for_on
		boton_if.text = "[ CONDICIONAL IF ]\nDESBLOQUEADO" if if_on else ("[ CONDICIONAL IF ]\n10 MINERALES" if for_on else "[ CONDICIONAL IF ]\nBLOQUEADO")

	if boton_expansion != null:
		boton_expansion.disabled = exp1_on
		boton_expansion.text = "[ CORREDOR 1X3 ]\nDESBLOQUEADO" if exp1_on else "[ CORREDOR 1X3 ]\n1 MINERAL"
	if boton_expansion_2 != null:
		boton_expansion_2.disabled = not (exp1_on and not exp2_on and MissionService.objective_id == "comprar_casillas")
		boton_expansion_2.text = "[ +3 CASILLAS ]\nDESBLOQUEADO" if exp2_on else ("[ +3 CASILLAS ]\n10 MINERALES" if exp1_on else "[ +3 CASILLAS ]\nBLOQUEADO")
	if boton_expansion_3 != null:
		boton_expansion_3.disabled = not (exp2_on and not exp3_on)
		boton_expansion_3.text = "[ SECTOR 3X3 ]\nDESBLOQUEADO" if exp3_on else ("[ SECTOR 3X3 ]\n20 MINERALES" if exp2_on else "[ SECTOR 3X3 ]\nBLOQUEADO")

	if boton_mineria != null:
		boton_mineria.disabled = mineria_rapida_desbloqueada
		boton_mineria.text = "[ MINERÍA RÁPIDA ]\nINSTALADO" if mineria_rapida_desbloqueada else "[ MINERÍA RÁPIDA ]\n15 MINERALES"

	if linea_prog_1 != null:
		linea_prog_1.default_color = Color(0.2, 0.8, 1.0) if while_on else Color(0.3, 0.33, 0.38)
	if linea_prog_2 != null:
		linea_prog_2.default_color = Color(0.2, 0.8, 1.0) if for_on else Color(0.3, 0.33, 0.38)
	if linea_prog_3 != null:
		linea_prog_3.default_color = Color(0.2, 0.8, 1.0) if if_on else Color(0.3, 0.33, 0.38)

	if linea_terr_1 != null:
		linea_terr_1.default_color = Color(0.3, 0.9, 0.5) if exp1_on else Color(0.3, 0.33, 0.38)
	if linea_terr_2 != null:
		linea_terr_2.default_color = Color(0.3, 0.9, 0.5) if exp2_on else Color(0.3, 0.33, 0.38)
	if linea_terr_3 != null:
		linea_terr_3.default_color = Color(0.3, 0.9, 0.5) if exp3_on else Color(0.3, 0.33, 0.38)

	if linea_hard_1 != null:
		linea_hard_1.default_color = Color(1.0, 0.84, 0.0) if mineria_rapida_desbloqueada else Color(0.3, 0.33, 0.38)

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
		if transmision_ada != null:
			transmision_ada.mostrar_mensaje(
				"Minerales insuficientes en la nave. Requiere %d minerales (tienes %d)." % [costo, minerales_nave],
				"error",
				4.0
			)
		
func _sumar_minerales_rover(cantidad: int) -> void:
	minerales_rover = mini(minerales_rover + cantidad, CAPACIDAD_ROVER)
	actualizar_contadores()
	_solicitar_guardado_progreso()
	
func procesar_transferencia() -> Dictionary:
	if mi_rover == null:
		return _crear_error_comando(
			"ejecucion",
			"No se encontró el rover."
		)

	if minerales_rover == 0:
		return _crear_error_comando(
			"ejecucion",
			"El rover no tiene minerales para transferir."
		)

	if minerales_nave >= CAPACIDAD_NAVE:
		return _crear_error_comando(
			"ejecucion",
			"La nave alcanzó su capacidad máxima."
		)

	var mundo := get_parent()

	if (
		mundo == null
		or not mundo.has_method("rover_esta_en_casilla_transferencia")
	):
		return _crear_error_comando(
			"ejecucion",
			"No se pudo comprobar la casilla de transferencia."
		)

	if not mundo.rover_esta_en_casilla_transferencia(mi_rover):
		return _crear_error_comando(
			"ejecucion",
			"Debes llevar el rover a la casilla inicial para transferir."
		)

	var espacio_disponible := CAPACIDAD_NAVE - minerales_nave
	var cantidad_transferida := mini(
		minerales_rover,
		espacio_disponible
	)

	minerales_nave += cantidad_transferida
	minerales_rover -= cantidad_transferida

	MissionService.registrar_transferencia(cantidad_transferida)

	actualizar_contadores()
	_solicitar_guardado_progreso()

	print(
		"Transferencia completada: ",
		cantidad_transferida,
		" minerales."
	)

	return {
		"ok": true,
		"error_type": "",
		"message": "",
		"minerals_transferred": cantidad_transferida,
		"steps_completed": 0
	}

func _crear_error_comando(
	tipo: String,
	mensaje: String
) -> Dictionary:
	print("Error A.D.A: ", mensaje)

	return {
		"ok": false,
		"error_type": tipo,
		"message": mensaje,
		"steps_completed": 0
	}
	
func _on_button_while_pressed() -> void:
	if GestorSintaxis.esta_desbloqueada("while"):
		return
	var costo: int = PRECIOS["while"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje(
			"Minerales insuficientes en la nave. Requiere %d minerales (tienes %d)." % [costo, minerales_nave],
			"error",
			4.0
		)
		return
	minerales_nave -= costo
	GestorSintaxis.desbloquear_sintaxis("while")
	MissionService.desbloquear_conocimiento("bucle_while")
	MissionService.registrar_compra_while()
	actualizar_contadores()
	actualizar_mejoras_visual()
	_solicitar_guardado_progreso()


func _on_button_for_pressed() -> void:
	if GestorSintaxis.esta_desbloqueada("for"):
		return
	if not GestorSintaxis.esta_desbloqueada("while"):
		transmision_ada.mostrar_mensaje(
			"Debes desbloquear el Bucle While primero.",
			"objetivo",
			5.0
		)
		return
	var costo: int = PRECIOS["for"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje(
			"Minerales insuficientes en la nave. Requiere %d minerales (tienes %d)." % [costo, minerales_nave],
			"error",
			4.0
		)
		return
	minerales_nave -= costo
	GestorSintaxis.desbloquear_sintaxis("for")
	GestorSintaxis.desbloquear_sintaxis("in range")
	MissionService.desbloquear_conocimiento("bucle_for")
	actualizar_contadores()
	actualizar_mejoras_visual()
	_solicitar_guardado_progreso()
	transmision_ada.mostrar_mensaje(
		"¡Módulo Bucle FOR instalado! Ahora puedes repetir secuencias con precisión.",
		"completado",
		6.0
	)


func _on_button_if_pressed() -> void:
	if GestorSintaxis.esta_desbloqueada("if"):
		return
	if not GestorSintaxis.esta_desbloqueada("for"):
		transmision_ada.mostrar_mensaje(
			"Debes desbloquear el Bucle For primero.",
			"objetivo",
			5.0
		)
		return
	var costo: int = PRECIOS["if"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje(
			"Minerales insuficientes en la nave. Requiere %d minerales (tienes %d)." % [costo, minerales_nave],
			"error",
			4.0
		)
		return
	minerales_nave -= costo
	GestorSintaxis.desbloquear_sintaxis("if")
	MissionService.desbloquear_conocimiento("condicional_if")
	MissionService.registrar_compra_if()
	actualizar_contadores()
	actualizar_mejoras_visual()
	_solicitar_guardado_progreso()


func _on_button_expansion_1_pressed() -> void:
	var mundo = get_parent()
	var costo: int = PRECIOS["mapa"]

	if mundo != null and mundo.corredor_1x3_desbloqueado:
		return

	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje(
			"Minerales insuficientes en la nave. Requiere %d mineral (tienes %d)." % [costo, minerales_nave],
			"error",
			4.0
		)
		return

	if mundo != null and mundo.expandir_corredor_1x3():
		minerales_nave -= costo
		actualizar_contadores()
		actualizar_mejoras_visual()
		MissionService.iniciar_ruta_calibracion()
		_solicitar_guardado_progreso()


func _on_button_expansion_2_pressed() -> void:
	var mundo := get_parent()
	if mundo == null or mundo.casillas_extra_desbloqueadas or MissionService.objective_id != "comprar_casillas":
		return
	if CodeExecutor.ejecutando:
		transmision_ada.mostrar_mensaje("Espera a que termine el programa antes de expandir el mapa.", "error")
		return
	var costo: int = PRECIOS["casillas_extra"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje("Necesitas 10 minerales en la nave. Recolecta y transfiere más minerales antes de comprar.", "error")
		return
	if mundo.expandir_tres_casillas():
		minerales_nave -= costo
		actualizar_contadores()
		MissionService.registrar_compra_casillas()
		actualizar_mejoras_visual()
		_solicitar_guardado_progreso()


func _on_button_expansion_3_pressed() -> void:
	var mundo := get_parent()
	if mundo == null or mundo.mapa_3x3_desbloqueado or not mundo.casillas_extra_desbloqueadas:
		return
	if CodeExecutor.ejecutando:
		transmision_ada.mostrar_mensaje("Espera a que termine el programa antes de expandir el mapa.", "error")
		return
	var costo: int = PRECIOS["mapa_3x3"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje("Necesitas %d minerales en la nave. Recolecta y transfiere más minerales antes de comprar." % costo, "error")
		return
	if mundo.expandir_mapa_3x3():
		minerales_nave -= costo
		actualizar_contadores()
		actualizar_mejoras_visual()
		_solicitar_guardado_progreso()
		transmision_ada.mostrar_mensaje(
			"¡Sector 3x3 desbloqueado! Terreno ampliado para mayores expediciones.",
			"completado",
			6.0
		)


func _on_button_mineria_pressed() -> void:
	if mineria_rapida_desbloqueada:
		return
	var costo: int = PRECIOS["mineria_rapida"]
	if minerales_nave < costo:
		transmision_ada.mostrar_mensaje(
			"Minerales insuficientes en la nave. Requiere %d minerales (tienes %d)." % [costo, minerales_nave],
			"error",
			4.0
		)
		return
	minerales_nave -= costo
	mineria_rapida_desbloqueada = true
	if mi_rover != null:
		mi_rover.tiempo_minado = 1.0
	actualizar_contadores()
	actualizar_mejoras_visual()
	_solicitar_guardado_progreso()
	transmision_ada.mostrar_mensaje(
		"¡Minería rápida instalada! El tiempo de extracción se redujo a 1 segundo.",
		"completado",
		6.0
	)
	
func _on_linea_iniciada(numero: int, contenido: String) -> void:
	print("Ejecutando línea ", numero, ": ", contenido)


func _on_error_detectado(error: Dictionary) -> void:
	print(
		"Error en línea ",
		error.get("line", 0),
		": ",
		error.get("message", "Error desconocido")
	)
	transmision_ada.mostrar_mensaje(
		"Detecte un problema en la instruccion: " +
		str(error.get("message", "Error desconocido")),
		"error",
		8.0
	)


func _on_ejecucion_finalizada(resultado: Dictionary) -> void:
	boton_ejecutar.text = "Ejecutar"
	print("Resultado de ejecución: ", resultado)
	actualizar_panel_mision(resultado)

	if (
		MissionService.objective_completed
		and MissionService.objective_id in [
			"ruta_calibracion",
			"ciclo_recoleccion"
		]
	):
		await get_tree().create_timer(2.5).timeout
		MissionService.preparar_mision_expansion()
		actualizar_mejoras_visual()
		_solicitar_guardado_progreso()

func _on_progreso_ejecucion(resultado: Dictionary) -> void:
	actualizar_panel_mision(resultado)


func _on_objetivo_actualizado(_mision_id: String, objetivo: String) -> void:
	actualizar_panel_mision()
	_animar_nueva_mision()


func _on_mision_completada(mision_id: String) -> void:
	label_estado_mision.text = "● COMPLETADA"
	_animar_mision_completada()
	match mision_id:
		"recolectar_primer_mineral":
			transmision_ada.mostrar_mensaje(
				"Excelente trabajo. Muestra recibida y almacenada. " +
				"Completaste la primera mision utilizando los metodos " +
				"minar y transferir.",
				"completado",
				10.0
			)

		"ruta_calibracion":
			transmision_ada.mostrar_mensaje(
				"Ruta calibrada. Excelente trabajo, unidad Rover.\n" +
				"Antes de continuar, revisa el Códice de A.D.A. para conocer " +
				"las herramientas disponibles. El módulo while puede ayudarte " +
				"a automatizar el siguiente desafío.",
				"completado",
				25.0
			)

		"ciclo_recoleccion":
			transmision_ada.mostrar_mensaje(
				"Diez minerales recibidos. Excelente automatización, " +
				"unidad Rover.",
				"completado",
				16.0
			)
		"comprar_casillas":
			transmision_ada.mostrar_mensaje(
				"Expansión completada. Compraste tres casillas y ahora hay dos depósitos de mineral distribuidos aleatoriamente en el mapa.",
				"completado", 10.0
			)
		"camino_largo":
			var msg_param := (
				"¡Excelente navegación! Has dominado el uso de parámetros.\n" +
				"Ahora puedes controlar la cantidad exacta de pasos en tus métodos.\n" +
				"Conocimiento desbloqueado: PARÁMETROS.\n"
			)
			if GestorSintaxis.esta_desbloqueada("if"):
				msg_param += "Como ya adquiriste el Condicional IF, ¡se activa la misión SEÑALES INCIERTAS!"
			else:
				msg_param += "Próximo paso: Adquiere el [ CONDICIONAL IF ] en Mejoras."
			transmision_ada.mostrar_mensaje(msg_param, "completado", 15.0)
		"comprar_if":
			transmision_ada.mostrar_mensaje(
				"¡Módulo Condicional IF instalado!\n" +
				"Sensores de análisis listos en el rover.\n" +
				"Nueva misión: SEÑALES INCIERTAS.\n" +
				"Usa 'if rover.hay_mineral():' para evaluar casillas antes de minar.",
				"progreso",
				12.0
			)
		"compra_temprana_if":
			transmision_ada.mostrar_mensaje(
				"¡Módulo Condicional IF adquirido!\n" +
				"Sintaxis y sensores listos. Se activarán en tu misión " +
				"cuando completes tus tareas de calibración actuales.",
				"progreso",
				10.0
			)
		"senales_inciertas":
			var msg_if := (
				"¡Lecturas confirmadas! Has dominado el condicional if y la lectura de sensores.\n" +
				"El rover ahora solo extrae recursos cuando detecta mineral.\n" +
				"Conocimiento desbloqueado: CONDICIONAL IF.\n"
			)
			if GestorSintaxis.esta_desbloqueada("while"):
				msg_if += "Como ya adquiriste el Bucle WHILE, ¡se activa la misión CICLO AUTÓNOMO!"
			else:
				msg_if += "Ahora puedes adquirir el [ BUCLE WHILE ] en Mejoras."
			transmision_ada.mostrar_mensaje(msg_if, "completado", 15.0)
		"comprar_while":
			transmision_ada.mostrar_mensaje(
				"¡Módulo Bucle WHILE instalado!\n" +
				"Capacidad de iteración condicional en línea.\n" +
				"Nueva misión: CICLO AUTÓNOMO.\n" +
				"Usa 'while rover.tiene_espacio():' para patrullar y extraer de forma continua.",
				"progreso",
				12.0
			)
		"compra_temprana_while":
			transmision_ada.mostrar_mensaje(
				"¡Módulo Bucle WHILE adquirido!\n" +
				"Registrado en la nave. Completa tus misiones previas " +
				"para iniciar los ejercicios de autonomía.",
				"progreso",
				10.0
			)
		"ciclo_autonomo":
			transmision_ada.mostrar_mensaje(
				"¡Autonomía completada! Has programado un bucle while que toma decisiones en tiempo real.\n" +
				"El rover ahora sabe cuándo continuar y cuándo volver a la base según sus sensores.\n" +
				"Conocimiento desbloqueado: BUCLE WHILE.",
				"completado",
				15.0
			)
		_:
			transmision_ada.mostrar_mensaje(
				"Mision completada correctamente.",
				"completado",
				8.0
			)
	# Guarda después de que MissionService marque la misión como completada.
	_solicitar_guardado_progreso()

func _on_conocimiento_desbloqueado(conocimiento_id: String) -> void:
	var nombre_concepto := conocimiento_id.replace("_", " ").to_upper()
	transmision_ada.mostrar_mensaje(
		"Nuevo conocimiento registrado: %s.\n\n" % nombre_concepto +
		"Revisa el Códice de A.D.A. para conocer sus posibilidades " +
		"antes de utilizarlo en tus próximas misiones.",
		"progreso",
		10.0
	)

func actualizar_panel_mision(resultado: Dictionary = {}) -> void:
	if label_mision == null:
		return
	var mision_id := MissionService.objective_id
	label_mision.text = mision_id.replace("_", " ").to_upper()
	label_objetivo_mision.text = _get_objetivo_panel(mision_id)

	if MissionService.objective_completed:
		label_estado_mision.text = "● COMPLETADA"
	else:
		label_estado_mision.text = "● EN CURSO"

func _animar_nueva_mision() -> void:
	if panel_mision == null:
		return
	var posicion_final := posicion_panel_mision
	panel_mision.position = posicion_final + Vector2(-18.0, 0.0)
	panel_mision.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_mision, "position", posicion_final, 0.35)
	tween.tween_property(panel_mision, "modulate:a", 1.0, 0.35)

func _animar_mision_completada() -> void:
	if panel_mision == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_mision, "modulate", Color(0.65, 1.0, 0.9, 1.0), 0.18)
	tween.tween_property(panel_mision, "modulate", Color.WHITE, 0.45)

func _get_objetivo_panel(mision_id: String) -> String:
	match mision_id:
		"recolectar_primer_mineral":
			return "Obtén y almacena tu primera muestra."
		"comprar_casillas":
			return "Amplía el sector de exploración."
		"ruta_calibracion":
			return "Completa una ruta de exploración y regresa a la base."
		"trabajo_continuo":
			return "Automatiza un ciclo de suministro repetitivo."
		"ciclo_recoleccion":
			return "Recolecta y entrega la cantidad requerida de minerales."
		"camino_largo":
			return "Navega una distancia extendida usando parámetros."
		"comprar_if":
			return "Adquiere el módulo de decisiones condicionales."
		"senales_inciertas":
			return "Haz que el rover reaccione a las señales del entorno."
		"comprar_while":
			return "Adquiere el módulo de automatización condicional."
		"ciclo_autonomo":
			return "Mantén una operación autónoma hasta completar la carga."
		_:
			return "Completa el objetivo de la misión actual."
	
func _mostrar_mensaje_inicial_ada() -> void:
	if MissionService.objective_completed:
		return
	transmision_ada.mostrar_mensaje(
		"Unidad Rover, enlace establecido. Soy A.D.A., " +
		"la inteligencia de la nave y tu asistente durante la exploración.\n\n" +
		"Antes de comenzar, revisa el Códice de A.D.A. " +
		"Allí encontrarás información sobre las herramientas " +
		"que puedes utilizar durante tus misiones.",
		"progreso",
		10.0
	)
