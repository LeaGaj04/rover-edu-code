extends Node

const RESOURCE := "player_attempts"

var http_request: HTTPRequest
var pending_attempts: Array[Dictionary] = []
var request_in_flight := false


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	if not CodeExecutor.ejecucion_finalizada.is_connected(_on_ejecucion_finalizada):
		CodeExecutor.ejecucion_finalizada.connect(_on_ejecucion_finalizada)
	Supabase.signed_out.connect(_on_signed_out)


func _on_ejecucion_finalizada(resultado: Dictionary) -> void:
	if not Supabase.is_authenticated():
		return
	var user_id := Supabase.get_current_user_id()
	var objective_id := str(resultado.get("objective_id", "")).strip_edges()
	if user_id.is_empty() or objective_id.is_empty():
		return
	pending_attempts.append({
		"user_id": user_id,
		"duration_seconds": maxf(0.0, float(resultado.get("duration_seconds", 0.0))),
		"objective_id": objective_id,
		"execution_success": bool(resultado.get("success", false)),
		"objective_completed": bool(resultado.get("objective_completed", false)),
		"error_type": str(resultado.get("error_type", ""))
	})
	_try_send_next()


func _try_send_next() -> void:
	if request_in_flight or pending_attempts.is_empty():
		return
	if not Supabase.is_authenticated():
		pending_attempts.clear()
		return
	var current_user_id := Supabase.get_current_user_id()
	var attempt: Dictionary = pending_attempts.pop_front()
	if current_user_id.is_empty() or attempt.get("user_id", "") != current_user_id:
		_try_send_next()
		return
	var headers := Supabase.get_authenticated_headers(
		PackedStringArray(["Prefer: return=minimal"])
	)
	request_in_flight = true
	var error := http_request.request(
		Supabase.get_rest_url(RESOURCE),
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(attempt)
	)
	if error != OK:
		request_in_flight = false
		print("No se pudo iniciar el guardado del intento.")
		_try_send_next()


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	_body: PackedByteArray
) -> void:
	request_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		print("No se pudo guardar el intento educativo.")
	if not Supabase.is_authenticated():
		pending_attempts.clear()
		return
	_try_send_next()


func _on_signed_out() -> void:
	pending_attempts.clear()
	if request_in_flight:
		http_request.cancel_request()
	request_in_flight = false
