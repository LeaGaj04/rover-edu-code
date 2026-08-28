extends CanvasLayer

@export var nodo_nave : Node3D

@onready var caja_codigo = $TextEdit
@export var mi_rover : CharacterBody3D

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
@onready var boton_expansion = $PanelTienda/LienzoArbol/ButtonExpansion1

const PRECIOS = {
	"while": 15,
	"for": 30,
	"mapa": 30
}

func _ready() -> void:
	# Oculta el árbol apenas arranca el juego
	if panel_tienda != null:
		panel_tienda.hide()
	
	# Actualizamos los textos al iniciar
	actualizar_contadores()
	# Conectamos la señal del rover a una nueva función de la interfaz
	if mi_rover != null:
		mi_rover.mineral_recolectado.connect(_sumar_minerales_rover)
	# Como ya conectaste la señal desde el editor (el ícono de wifi en la foto),
	# NO necesitamos conectarla por código aquí. ¡Así que lo dejamos limpio!


func _on_boton_tienda_pressed() -> void:
	panel_tienda.visible = !panel_tienda.visible
	
	if panel_tienda.visible:
		boton_tienda.text = "Cerrar Árbol"
	else:
		boton_tienda.text = "Abrir Tienda"


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.ctrl_pressed and event.keycode == KEY_ENTER:
		get_viewport().set_input_as_handled()
		_on_button_pressed()


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
		
		ejecutar_movimiento_rover(comando, pasos)


func ejecutar_movimiento_rover(comando: String, pasos: int) -> void:
	if mi_rover == null:
		print("Error: El Rover no está asignado en el Inspector.")
		return
		
	print("Ejecutando: ", comando, " (", pasos, " pasos)")
	
	if comando == "norte":
		mi_rover.norte(pasos)
	elif comando == "sur":
		mi_rover.sur(pasos)
	elif comando == "este":
		mi_rover.este(pasos)
	elif comando == "oeste":
		mi_rover.oeste(pasos)
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
	
	# Restauramos el texto del botón principal para que vuelva a decir "Abrir Tienda"
	boton_tienda.text = "Abrir Tienda"
	
func actualizar_contadores() -> void:
	if label_nave != null:
		label_nave.text = "Nave: " + str(minerales_nave) + "/" + str(CAPACIDAD_NAVE)
	if label_rover != null:
		label_rover.text = "Rover: " + str(minerales_rover) + "/" + str(CAPACIDAD_ROVER)

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
	else:
		print("Minerales insuficientes para comprar: " + item_id)
		
func _sumar_minerales_rover(cantidad: int) -> void:
	minerales_rover = mini(minerales_rover + cantidad, CAPACIDAD_ROVER)
	actualizar_contadores()
	
func procesar_transferencia() -> void:
	if nodo_nave == null:
		print("Error: La Nave no está asignada en el Inspector.")
		return
		
	if minerales_rover == 0:
		print("El Rover no tiene minerales para transferir.")
		return

	if minerales_nave >= CAPACIDAD_NAVE:
		print("La Nave está llena. Capacidad máxima: ", CAPACIDAD_NAVE, " minerales.")
		return
		
	# Calculamos la distancia entre el rover y la nave
	var distancia = mi_rover.global_position.distance_to(nodo_nave.global_position)
	
	# Si la distancia es menor a 2.5 unidades
	if distancia <= 5.0:
		var espacio_disponible = CAPACIDAD_NAVE - minerales_nave
		var cantidad_transferida = mini(minerales_rover, espacio_disponible)
		print("Iniciando transferencia segura... ", cantidad_transferida, " minerales enviados a la Nave.")

		minerales_nave += cantidad_transferida
		minerales_rover -= cantidad_transferida
		
		# Actualizamos los números en pantalla
		actualizar_contadores()
	else:
		print("Error de transferencia: El Rover está muy lejos de la base.")
		
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


func _on_button_expansion_2_pressed() -> void:
	# La segunda expansión queda reservada para una implementación futura.
	print("EX Mapa 2 todavía no está disponible.")
	
