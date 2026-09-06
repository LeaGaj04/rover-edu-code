extends Control

const ESCENA_MENU := "res://escenas/menu_inicio.tscn"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_alternar_menu_pausa()
		get_viewport().set_input_as_handled()


func _alternar_menu_pausa() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		get_viewport().gui_release_focus()


func _on_boton_salir_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(ESCENA_MENU)


func _exit_tree() -> void:
	get_tree().paused = false
