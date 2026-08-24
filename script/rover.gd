extends CharacterBody3D

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
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", destino, 0.4)
		await tween.finished # Espera a que termine cada animación
		
	esta_moviendose = false
