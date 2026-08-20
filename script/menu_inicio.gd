extends Control

# Ruta hacia la escena del juego donde está el asteroide y el Rover
const ESCENA_MUNDO = "res://escenas/mundo.tscn"

func _ready() -> void:
	pass # Se ejecuta al iniciar el menú

# Se ejecuta al hacer clic en "Jugar"
func _on_boton_jugar_pressed() -> void:
	if ResourceLoader.exists(ESCENA_MUNDO):
		get_tree().change_scene_to_file(ESCENA_MUNDO)
	else:
		print("No se encontró la escena en la ruta: ", ESCENA_MUNDO)

# Se ejecuta al hacer clic en "Salir"
func _on_boton_salir_pressed() -> void:
	get_tree().quit()
