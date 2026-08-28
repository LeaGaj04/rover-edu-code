extends CharacterBody3D

signal mineral_recolectado(cantidad)

# Distancia de cada paso en unidades 3D (el tamaño de tu casilla)
var paso_distancia: float = 2.0

# Control de la cola de movimiento
var cola_instrucciones: Array = []
var esta_moviendose: bool = false


# --- FUNCIONES DE MOVIMIENTO (Aceptan cantidad de pasos) ---

func norte(pasos: int = 1) -> void:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.FORWARD)
	_intentar_mover()

func sur(pasos: int = 1) -> void:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.BACK)
	_intentar_mover()

func oeste(pasos: int = 1) -> void:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.LEFT)
	_intentar_mover()

func este(pasos: int = 1) -> void:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.RIGHT)
	_intentar_mover()


# --- PROCESADOR AUTOMÁTICO EN SEGUNDO PLANO ---

func _intentar_mover() -> void:
	if esta_moviendose:
		return
		
	esta_moviendose = true
	
	while cola_instrucciones.size() > 0:
		var direccion = cola_instrucciones.pop_front()
		var destino = global_position + (direccion * paso_distancia)

		if not _destino_esta_desbloqueado(destino):
			print("Movimiento bloqueado: esa casilla todavía no está comprada.")
			cola_instrucciones.clear()
			break
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", destino, 0.4)
		await tween.finished # Espera a que termine cada animación
		
	esta_moviendose = false


func _destino_esta_desbloqueado(destino_global: Vector3) -> bool:
	var grid_map := get_parent() as GridMap
	if grid_map == null:
		push_warning("El Rover debe ser hijo de un GridMap para validar sus límites.")
		return false

	var destino_local := grid_map.to_local(destino_global)
	var casilla := grid_map.local_to_map(destino_local)
	# El movimiento es horizontal; ignoramos cualquier variación de altura del modelo.
	casilla.y = 0
	return grid_map.get_cell_item(casilla) != GridMap.INVALID_CELL_ITEM


func minar():
	print("Rover posicionado. Iniciando protocolo de minería...")
	
	# Pausa la ejecución por 3 segundos
	await get_tree().create_timer(3.0).timeout
	
	print("Minería completada. Buscando mineral en la zona...")
	
	# Verificar si hay un mineral en la misma posición usando un Area3D interna
	# o revisando las distancias a los objetos del grupo 'minerales'
	var minerales_en_mapa = get_tree().get_nodes_in_group("minerales")
	var mineral_minado = false
	
	for mineral in minerales_en_mapa:
		# Si el mineral está muy cerca del rover (en la misma casilla)
		if global_position.distance_to(mineral.global_position) < paso_distancia:
			var nodo_mineral = mineral.get_parent()
			nodo_mineral.queue_free() # Desaparece el mineral completo
			mineral_minado = true
			
			# El Mundo es el abuelo del Rover porque este cuelga del GridMap.
			get_parent().get_parent().spawn_mineral_aleatorio()
			print("¡Diamante recolectado! Reapareciendo en la casilla inicial.")
			mineral_recolectado.emit(1) # Aquí le avisa al juego y manda el valor de 10
			break # Solo minamos uno a la vez
			
	if not mineral_minado:
		print("Error: No hay ningún mineral en esta casilla.")
