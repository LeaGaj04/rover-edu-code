extends Control

const ESCENA_MENU := "res://escenas/menu_inicio.tscn"
@onready var email_input: LineEdit = $Panel/Contenedor/Email
@onready var password_input: LineEdit = $Panel/Contenedor/Password
@onready var login_button: Button = $Panel/Contenedor/IniciarSesion
@onready var signup_button: Button = $Panel/Contenedor/Registrarse
@onready var status_label: Label = $Panel/Contenedor/Mensaje

func _ready() -> void:
	Supabase.login_succeeded.connect(_on_login_succeeded)
	Supabase.login_failed.connect(_on_login_failed)
	Supabase.signup_succeeded.connect(_on_signup_succeeded)
	Supabase.signup_failed.connect(_on_signup_failed)
	var panel := $Panel
	panel.modulate.a = 0.0
	panel.position.y += 12.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "position:y", panel.position.y - 12.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_iniciar_sesion_pressed() -> void:
	if not _validar_campos():
		return
	_set_request_state(true, "Iniciando sesión...")
	if not Supabase.sign_in(email_input.text.strip_edges(), password_input.text):
		_set_request_state(false, "Ya hay una operación en curso.")

func _on_registrarse_pressed() -> void:
	if not _validar_campos():
		return
	_set_request_state(true, "Creando cuenta...")
	if not Supabase.sign_up(email_input.text.strip_edges(), password_input.text):
		_set_request_state(false, "Ya hay una operación en curso.")

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(ESCENA_MENU)

func _validar_campos() -> bool:
	if email_input.text.strip_edges().is_empty():
		status_label.text = "Escribe tu correo electrónico."
		return false
	if password_input.text.is_empty():
		status_label.text = "Escribe tu contraseña."
		return false
	return true

func _set_request_state(in_progress: bool, message: String) -> void:
	login_button.disabled = in_progress
	signup_button.disabled = in_progress
	status_label.text = message

func _on_login_succeeded(_user: Dictionary) -> void:
	_set_request_state(false, "Sesión iniciada.")
	get_tree().change_scene_to_file(ESCENA_MENU)

func _on_login_failed(message: String) -> void:
	_set_request_state(false, "No se pudo iniciar sesión: " + message)

func _on_signup_succeeded(_user: Dictionary, has_session: bool) -> void:
	_set_request_state(false, "Cuenta creada. Revisa tu correo para confirmar tu cuenta." if not has_session else "Cuenta creada.")
	if has_session:
		get_tree().change_scene_to_file(ESCENA_MENU)

func _on_signup_failed(message: String) -> void:
	_set_request_state(false, "No se pudo registrar la cuenta: " + message)
