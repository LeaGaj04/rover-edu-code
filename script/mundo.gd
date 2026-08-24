extends Node3D

@export var mineral_scene : PackedScene
@onready var grid_map = $GridMap

# Variable que define el tamaño del mapa actual
# 0 = mapa 1x1 (inicio)
# 1 = mapa 3x3
# 2 = mapa 5x5, etc.
var radio_mapa_desbloqueado : int = 1 
var max_minerales : int = 4

func _ready():
	generar_minerales_iniciales()

func generar_minerales_iniciales():
	# Si el radio es 0 (solo 1 casilla), solo hacemos aparecer 1 mineral
	if radio_mapa_desbloqueado == 0:
		max_minerales = 1
	
	for i in range(max_minerales):
		spawn_mineral_aleatorio()

func spawn_mineral_aleatorio():
   # 1. Elegimos las coordenadas de la cuadrícula (como si fueran casillas)
	var casilla_x = randi_range(-radio_mapa_desbloqueado, radio_mapa_desbloqueado)
	var casilla_z = randi_range(-radio_mapa_desbloqueado, radio_mapa_desbloqueado)
	
	# 2. Le pedimos al GridMap que nos dé el centro milimétrico de esa casilla
	var centro_exacto = grid_map.map_to_local(Vector3i(casilla_x, 0, casilla_z))
	
	# 3. Instanciamos el mineral
	var nuevo_mineral = mineral_scene.instantiate()
	add_child(nuevo_mineral)
	
	# 4. Lo posicionamos en ese centro exacto, ajustando solo la altura (Y) a 0.5
	nuevo_mineral.position = Vector3(centro_exacto.x, 0.5, centro_exacto.z)
