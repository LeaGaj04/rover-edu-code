extends Node

signal login_succeeded(user: Dictionary)
signal login_failed(message: String)
signal signup_succeeded(user: Dictionary, has_session: bool)
signal signup_failed(message: String)
signal password_recovery_sent
signal password_recovery_failed(message: String)
signal signed_out

const SUPABASE_URL := "https://ulivinilxszdyazignbi.supabase.co"
const SUPABASE_KEY := "sb_publishable_Nk8m4AZRU1ffH6gJCF45pw_KI-H6-LK"
var http_request: HTTPRequest
var access_token := ""
var refresh_token := ""
var current_user: Dictionary = {}
var pending_operation := ""

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func sign_up(email: String, password: String) -> bool:
	return _start_auth_request("signup", SUPABASE_URL + "/auth/v1/signup", email, password)

func sign_in(email: String, password: String) -> bool:
	return _start_auth_request("login", SUPABASE_URL + "/auth/v1/token?grant_type=password", email, password)

func send_password_recovery(email: String) -> bool:
	if pending_operation != "":
		return false
	pending_operation = "password_recovery"
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Content-Type: application/json",
		"Accept: application/json"
	])
	var error := http_request.request(
		SUPABASE_URL + "/auth/v1/recover",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({"email": email})
	)
	if error != OK:
		pending_operation = ""
		password_recovery_failed.emit("No se pudo iniciar la conexión con Supabase.")
		return false
	return true

func test_connection() -> bool:
	if pending_operation != "":
		return false
	pending_operation = "connection_test"
	var headers := PackedStringArray(["apikey: " + SUPABASE_KEY, "Accept: application/json"])
	var error := http_request.request(SUPABASE_URL + "/rest/v1/connection_test?select=*", headers, HTTPClient.METHOD_GET)
	if error != OK:
		pending_operation = ""
		return false
	return true

func get_current_user() -> Dictionary:
	return current_user.duplicate(true)

func get_current_user_id() -> String:
	return str(current_user.get("id", ""))

func is_authenticated() -> bool:
	return not access_token.is_empty() and not current_user.is_empty()

func sign_out() -> void:
	var token := access_token
	access_token = ""
	refresh_token = ""
	current_user = {}
	signed_out.emit()
	if token.is_empty() or pending_operation != "":
		return
	pending_operation = "logout"
	var headers := PackedStringArray(["apikey: " + SUPABASE_KEY, "Authorization: Bearer " + token, "Content-Type: application/json"])
	var error := http_request.request(SUPABASE_URL + "/auth/v1/logout", headers, HTTPClient.METHOD_POST)
	if error != OK:
		pending_operation = ""

func _start_auth_request(operation: String, endpoint: String, email: String, password: String) -> bool:
	if pending_operation != "":
		return false
	pending_operation = operation
	var headers := PackedStringArray(["apikey: " + SUPABASE_KEY, "Content-Type: application/json", "Accept: application/json"])
	var error := http_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify({"email": email, "password": password}))
	if error != OK:
		pending_operation = ""
		_emit_failure(operation, "No se pudo iniciar la conexión con Supabase.")
		return false
	return true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var operation := pending_operation
	pending_operation = ""
	var data = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS:
		if operation == "logout":
			return
		if operation == "connection_test":
			print("No se pudo conectar con Supabase.")
			return
		_emit_failure(operation, "No se pudo conectar con Supabase.")
		return
	if response_code < 200 or response_code >= 300:
		if operation == "logout":
			return
		if operation == "connection_test":
			print("Error conectando con Supabase. Código HTTP: ", response_code)
			return
		_emit_failure(operation, _extract_error_message(data))
		return
	if typeof(data) != TYPE_DICTIONARY:
		if operation == "connection_test":
			print("Error en la respuesta de conexión con Supabase.")
			return
		_emit_failure(operation, "Supabase devolvió una respuesta inesperada.")
		return
	if operation == "connection_test":
		print("EduCode conectado correctamente a Supabase.")
		return
	if operation == "password_recovery":
		password_recovery_sent.emit()
		return
	var user_data: Dictionary = data.get("user", {})
	var new_access_token := str(data.get("access_token", ""))
	if not new_access_token.is_empty():
		access_token = new_access_token
		refresh_token = str(data.get("refresh_token", ""))
		current_user = user_data
	if operation == "login":
		login_succeeded.emit(current_user)
	else:
		signup_succeeded.emit(user_data, not new_access_token.is_empty())

func _extract_error_message(data) -> String:
	if typeof(data) == TYPE_DICTIONARY:
		for key in ["msg", "message", "error_description", "error"]:
			if data.has(key) and not str(data[key]).is_empty():
				return str(data[key])
	return "La operación de autenticación no pudo completarse."

func _emit_failure(operation: String, message: String) -> void:
	if operation == "login":
		login_failed.emit(message)
	elif operation == "password_recovery":
		password_recovery_failed.emit(message)
	else:
		signup_failed.emit(message)
