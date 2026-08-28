extends Node3D

@export var mineral_scene : PackedScene
@onready var grid_map = $GridMap

const CASILLA_INICIAL := Vector3i(0, 0, 0)

# Variable que define el tamaño del mapa actual
# 0 = mapa 1x1 (inicio)
# 1 = mapa 3x3
# 2 = mapa 5x5, etc.
var radio_mapa_desbloqueado : int = 0
var max_minerales : int = 1
var mapa_3x3_desbloqueado : bool = false

func _ready():
	# El jugador comienza solamente con la casilla central.
	grid_map.clear()
	grid_map.set_cell_item(CASILLA_INICIAL, 1)
	generar_minerales_iniciales()

func generar_minerales_iniciales():
	# Si el radio es 0 (solo 1 casilla), solo hacemos aparecer 1 mineral
	if radio_mapa_desbloqueado == 0:
		max_minerales = 1
	
	for i in range(max_minerales):
		spawn_mineral_aleatorio()

func spawn_mineral_aleatorio():
	# Mientras el mapa está bloqueado, el mineral reaparece siempre en la
	# única casilla disponible para que el jugador pueda farmearlo.
	var centro_exacto = grid_map.map_to_local(CASILLA_INICIAL)
	
	# 3. Instanciamos el mineral
	var nuevo_mineral = mineral_scene.instantiate()
	add_child(nuevo_mineral)
	
	# 4. Lo posicionamos en ese centro exacto, ajustando solo la altura (Y) a 0.5
	nuevo_mineral.position = Vector3(centro_exacto.x, 0.5, centro_exacto.z)


func expandir_mapa_3x3() -> bool:
	if mapa_3x3_desbloqueado:
		return false

	for x in range(-1, 2):
		for z in range(-1, 2):
			var tipo_casilla = 1 if (x + z) % 2 == 0 else 2
			grid_map.set_cell_item(Vector3i(x, 0, z), tipo_casilla)

	radio_mapa_desbloqueado = 1
	mapa_3x3_desbloqueado = true
	print("Mapa 1 adquirido: terreno expandido a 3x3.")
	return true
