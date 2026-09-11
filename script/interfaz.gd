extends CanvasLayer

@onready var panel_codigo: Panel = $PanelCodigo
@onready var barra_codigo: Panel = $PanelCodigo/BarraTitulo
@onready var contenido_codigo: Control = $PanelCodigo/Contenido
@onready var boton_minimizar: Button = $PanelCodigo/BarraTitulo/BotonMinimizar
@onready var caja_codigo: TextEdit = $PanelCodigo/Contenido/TextEdit
@onready var transmision_ada = $TransmisionADA
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

# --- REFERENCIAS A LA TIENDA Y CÓDICE ---
@onready var panel_tienda = $PanelTienda
@onready var boton_tienda = $ContenedorTienda/BotonTienda
@onready var panel_archivo = $ArchivoADA
@onready var boton_archivo = $ContenedorTienda/BotonArchivo
@onready var boton_while = $PanelTienda/LienzoArbol/ButtonWhile
@onready var boton_for = $PanelTienda/LienzoArbol/ButtonFor
@onready var boton_if = $PanelTienda/LienzoArbol/ButtonIf
@onready var boton_expansion = $PanelTienda/LienzoArbol/ButtonExpansion1
@onready var boton_expansion_2: Button = $PanelTienda/LienzoArbol/ButtonExpansion2

const PRECIOS = {
	"while": 15,
	"for": 30,
	"mapa": 1,
	"casillas_extra": 10,
	"if": 15
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
	MissionService.objetivo_actualizado.connect(_on_objetivo_actualizado)
	MissionService.mision_completada.connect(_on_mision_completada)
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
	var resultado: Dictionary = await CodeExecutor.ejecutar_codigo(
		caja_codigo.text,
		ejecutar_movimiento_rover,
		evaluar_condicion_rover
	)
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
	if condicion == "rover.hay_mineral()" or condicion == "hay_mineral()":
		return mi_rover.hay_mineral()
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
	}


func _solicitar_guardado_progreso() -> void:
	ProgressService.save_progress(get_progress_state())


func actualizar_mejoras_visual() -> void:
	if boton_expansion_2 != null:
		boton_expansion_2.disabled = get_parent().casillas_extra_desbloqueadas or MissionService.objective_id != "comprar_casillas"
	if boton_while != null:
		boton_while.disabled = GestorSintaxis.esta_desbloqueada("while")
	if boton_for != null:
		boton_for.disabled = GestorSintaxis.esta_desbloqueada("for")
	if boton_if != null:
		boton_if.disabled = GestorSintaxis.esta_desbloqueada("if")
	if boton_expansion != null:
		var mundo := get_parent()
		boton_expansion.disabled = (
	mundo != null
	and mundo.corredor_1x3_desbloqueado
)

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
	
func _on_button_for_pressed() -> void:
	transmision_ada.mostrar_mensaje(
		"El módulo for se desbloquea gratuitamente " +
		"al completar la Ruta de calibración.",
		"objetivo",
		8.0
	)
func _on_button_while_pressed() -> void:
	transmision_ada.mostrar_mensaje(
		"El bucle while está en desarrollo para futuras misiones de automatización.",
		"objetivo",
		6.0
	)

func _on_button_if_pressed() -> void:
	intentar_compra("if", boton_if, $PanelTienda/LienzoArbol/Line2D3)
	if GestorSintaxis.esta_desbloqueada("if"):
		MissionService.desbloquear_conocimiento("condicional_if")

func _on_button_expansion_1_pressed() -> void:
	var mundo = get_parent()
	var costo = PRECIOS["mapa"]

	if mundo.corredor_1x3_desbloqueado:
		print("El corredor 1x3 ya está desbloqueado.")
		return

	if minerales_nave < costo:
		print("Minerales insuficientes en la Nave. Mapa 1 cuesta ", costo, " minerales.")
		return

	if mundo.expandir_corredor_1x3():
		minerales_nave -= costo
		actualizar_contadores()
		boton_expansion.disabled = true
		MissionService.iniciar_ruta_calibracion()
		_solicitar_guardado_progreso()


func _on_button_expansion_2_pressed() -> void:
	var mundo := get_parent()
	if mundo.casillas_extra_desbloqueadas or MissionService.objective_id != "comprar_casillas":
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
	print("Resultado de ejecución: ", resultado)

	if (
		MissionService.objective_completed
		and MissionService.objective_id in [
			"ruta_calibracion",
			"ciclo_recoleccion"
		]
	):
		MissionService.preparar_mision_expansion()
		actualizar_mejoras_visual()
		_solicitar_guardado_progreso()


func _on_objetivo_actualizado(_mision_id: String, objetivo: String) -> void:
	transmision_ada.mostrar_mensaje(objetivo, "progreso", 8.0)


func _on_mision_completada(mision_id: String) -> void:
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
				"Ruta calibrada. Módulo for desbloqueado.\n" +
				"Un bucle repite un grupo de instrucciones. " +
				"Por ejemplo, for ciclo in range(2): repite dos veces " +
				"las instrucciones con sangría que aparecen debajo.\n" +
				"Ahora automatiza la recolección de 10 minerales " +
				"y transfiérelos una sola vez al final. " +
				"Deja la transferencia fuera del bucle.",
				"completado",
				25.0
			)

		"ciclo_recoleccion":
			transmision_ada.mostrar_mensaje(
				"Diez minerales recibidos. Automatizaste la recolección " +
				"utilizando un bucle y ejecutaste la transferencia al final.\n" +
				"Ahora puedes comprar +3 CASILLAS en Mejoras " +
				"con 10 minerales de la nave.",
				"completado",
				16.0
			)
		"comprar_casillas":
			transmision_ada.mostrar_mensaje(
				"Expansión completada. Compraste tres casillas y ahora hay dos depósitos de mineral distribuidos aleatoriamente en el mapa.",
				"completado", 10.0
			)
		"camino_largo":
			transmision_ada.mostrar_mensaje(
				"¡Excelente navegación! Has dominado el uso de parámetros.\n" +
				"Ahora puedes controlar la cantidad exacta de pasos en tus métodos " +
				"sin necesidad de repetir instrucciones innecesarias.\n" +
				"Conocimiento desbloqueado: PARÁMETROS.",
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
	
func _mostrar_mensaje_inicial_ada() -> void:
	if MissionService.objective_id == "camino_largo" and not MissionService.objective_completed:
		transmision_ada.mostrar_mensaje(
			MissionService.get_objetivo_actual(),
			"objetivo",
			15.0
		)
		return
	if MissionService.objective_id == "ciclo_recoleccion":
		transmision_ada.mostrar_mensaje(
			MissionService.get_objetivo_actual(),
			"objetivo",
			25.0
		)
		return
	if MissionService.objective_id == "comprar_casillas":
		transmision_ada.mostrar_mensaje(MissionService.get_objetivo_actual(), "objetivo", 10.0)
		return
	if MissionService.objective_completed:
		transmision_ada.mostrar_mensaje(
			"Bienvenido nuevamente, unidad Rover. La primera muestra ya fue procesada. " +
			"El siguiente paso es ampliar la zona de exploracion desde el arbol de mejoras.",
			"objetivo",
			9.0
		)
		return

	match MissionService.estado_actual:
		MissionService.EstadoMision.TRANSFERIR_MINERAL:
			transmision_ada.mostrar_mensaje(
				"La muestra sigue almacenada en tu inventario. " +
				"Ejecuta rover.transferir() para enviarla a la nave.",
				"objetivo",
				8.0
			)

		_:
			transmision_ada.mostrar_mensaje(
				"Unidad Rover, enlace establecido. Soy A.D.A., la inteligencia de la nave. " +
				"Para extraer la primera muestra utiliza rover.minar().",
				"objetivo",
				8.0
			)
