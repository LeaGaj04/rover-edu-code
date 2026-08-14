extends CanvasLayer

@onready var caja_codigo = $TextEdit
@export var mi_rover : CharacterBody3D

func _on_button_pressed():
	var codigo_jugador = caja_codigo.text
	
	if codigo_jugador.strip_edges() == "rover.avanzar()":
		mi_rover.avanzar()
	else:
		print("Sintaxis incorrecta o comando no reconocido")
