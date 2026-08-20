extends CharacterBody3D

# Distancia de cada paso en unidades 3D
var paso_distancia: float = 2.0


# --- FUNCIÓN AVANZAR ---
func avanzar():
	print("Modelo 3D: ¡Recibí la orden de AVANZAR!")
	# Avanza hacia el FRENTE local del Rover (donde apunta su modelo)
	global_position -= transform.basis.z * paso_distancia


# --- FUNCIÓN IZQUIERDA ---
func izquierda():
	print("Modelo 3D: ¡Recibí la orden de girar a la IZQUIERDA!")
	# Rotamos +90 grados en el eje Y (convertidos a radianes)
	rotate_y(deg_to_rad(90.0))


# --- FUNCIÓN DERECHA ---
func derecha():
	print("Modelo 3D: ¡Recibí la orden de girar a la DERECHA!")
	# Rotamos -90 grados en el eje Y (convertidos a radianes)
	rotate_y(deg_to_rad(-90.0))
