extends Control

const ESCENA_MENU := "res://escenas/menu_inicio.tscn"
@onready var correo: Label = $Panel/Contenedor/Correo
@onready var estado: Label = $Panel/Contenedor/Estado

func _ready() -> void:
	var user := Supabase.get_current_user()
	correo.text = "Correo: " + str(user.get("email", "No disponible"))
	estado.text = "Estado: Sesión autenticada" if Supabase.is_authenticated() else "Estado: Sin sesión"

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_MENU)
