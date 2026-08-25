extends CanvasLayer

@onready var caja_codigo = $TextEdit
@export var mi_rover : CharacterBody3D

# --- REFERENCIAS A LA TIENDA ---
# ¡Aquí estaba el detalle! Usamos los nombres exactos de tu foto
@onready var panel_tienda = $PanelTienda
@onready var boton_tienda = $ContenedorTienda/BotonTienda


func _ready() -> void:
	# Oculta el árbol apenas arranca el juego
	if panel_tienda != null:
		panel_tienda.hide()
		
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
	elif "rover.minar()":
		await mi_rover.minar()
	else:
		print("Error A.D.A: El rover no conoce el comando '", comando, "'")


func _on_boton_cerrar_pressed() -> void:
	# Ocultamos el panel directamente
	panel_tienda.hide()
	
	# Restauramos el texto del botón principal para que vuelva a decir "Abrir Tienda"
	boton_tienda.text = "Abrir Tienda"
