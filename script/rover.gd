extends CharacterBody3D

# Distancia de cada paso en unidades 3D (el tamaño exacto de tu casilla)
var paso_distancia: float = 2.0


# --- FUNCIÓN NORTE ---
func norte():
	print("Modelo 3D: ¡Me muevo hacia el NORTE!")
	# Vector3.FORWARD mueve siempre en el eje -Z absoluto
	global_position += Vector3.FORWARD * paso_distancia


# --- FUNCIÓN SUR ---
func sur():
	print("Modelo 3D: ¡Me muevo hacia el SUR!")
	# Vector3.BACK mueve siempre en el eje +Z absoluto
	global_position += Vector3.BACK * paso_distancia


# --- FUNCIÓN OESTE ---
func oeste():
	print("Modelo 3D: ¡Me muevo hacia el OESTE!")
	# Vector3.LEFT mueve siempre en el eje -X absoluto
	global_position += Vector3.LEFT * paso_distancia


# --- FUNCIÓN ESTE ---
func este():
	print("Modelo 3D: ¡Me muevo hacia el ESTE!")
	# Vector3.RIGHT mueve siempre en el eje +X absoluto
	global_position += Vector3.RIGHT * paso_distancia
