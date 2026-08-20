extends DirectionalLight3D

# Velocidad a la que gira el sol. Un número mayor hace que los días pasen más rápido.
@export var velocidad_rotacion: float = 10.0 

func _process(delta):
	# Rotamos el sol en el eje X para simular el paso de las horas
	rotation_degrees.x -= velocidad_rotacion * delta
