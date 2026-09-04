extends CharacterBody3D

signal mineral_recolectado(cantidad)

# Distancia de cada paso en unidades 3D (el tamaño de tu casilla)
var paso_distancia: float = 2.0

# Control de la cola de movimiento
var cola_instrucciones: Array = []
var esta_moviendose: bool = false


# --- FUNCIONES DE MOVIMIENTO (Aceptan cantidad de pasos) ---

func norte(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.FORWARD)

	return await _intentar_mover()


func sur(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.BACK)

	return await _intentar_mover()


func oeste(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.LEFT)

	return await _intentar_mover()


func este(pasos: int = 1) -> Dictionary:
	for i in range(pasos):
		cola_instrucciones.append(Vector3.RIGHT)

	return await _intentar_mover()


func _intentar_mover() -> Dictionary:
	var pasos_completados := 0

	if esta_moviendose:
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "El rover ya está ejecutando otro movimiento.",
			"steps_completed": pasos_completados
		}

	esta_moviendose = true

	while cola_instrucciones.size() > 0:
		var direccion: Vector3 = cola_instrucciones.pop_front()
		var destino := global_position + direccion * paso_distancia

		if not _destino_esta_desbloqueado(destino):
			cola_instrucciones.clear()
			esta_moviendose = false

			return {
				"ok": false,
				"error_type": "ejecucion",
				"message": (
					"Movimiento bloqueado: esa casilla todavía no está disponible."
				),
				"steps_completed": pasos_completados
			}

		var tween := create_tween()
		tween.tween_property(
			self,
			"global_position",
			destino,
			0.4
		)

		await tween.finished
		pasos_completados += 1

	esta_moviendose = false

	return {
		"ok": true,
		"error_type": "",
		"message": "",
		"steps_completed": pasos_completados
	}


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


func minar() -> Dictionary:
	var grid_map := get_parent() as GridMap
	if grid_map == null:
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "No se pudo comprobar la casilla actual del rover.",
			"minerals_collected": 0,
			"steps_completed": 0
		}

	var posicion_rover_local := grid_map.to_local(global_position)
	var casilla_rover := grid_map.local_to_map(posicion_rover_local)
	casilla_rover.y = 0
	var minerales_en_mapa := get_tree().get_nodes_in_group("minerales")

	for mineral in minerales_en_mapa:
		var nodo_mineral := mineral.get_parent() as Node3D
		if nodo_mineral == null:
			continue

		var posicion_mineral_local := grid_map.to_local(
			nodo_mineral.global_position
		)
		var casilla_mineral := grid_map.local_to_map(posicion_mineral_local)
		casilla_mineral.y = 0

		if casilla_rover == casilla_mineral:
			print("Rover posicionado. Iniciando protocolo de minería...")
			await get_tree().create_timer(3.0).timeout

			if is_instance_valid(nodo_mineral):
				nodo_mineral.queue_free()
			get_parent().get_parent().spawn_mineral_aleatorio()
			mineral_recolectado.emit(1)

			print("Mineral recolectado correctamente.")

			return {
				"ok": true,
				"error_type": "",
				"message": "",
				"minerals_collected": 1,
				"steps_completed": 0
			}

	print("Error: No hay ningún mineral en esta casilla.")

	return {
		"ok": false,
		"error_type": "ejecucion",
		"message": "No existe un mineral en la casilla actual.",
		"minerals_collected": 0,
		"steps_completed": 0
	}
