extends Node

signal progress_loaded(progress: Dictionary)
signal progress_load_failed(message: String)

const RESOURCE := "player_progress"
const SELECT_FIELDS := "user_id,minerals_ship,minerals_rover,map_tier,unlocked_syntax,created_at,updated_at"

var current_progress: Dictionary = {}
var http_request: HTTPRequest
var loading := false
var pending_operation := ""
var pending_user_id := ""

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	Supabase.signed_out.connect(clear_progress)

func load_progress() -> bool:
	if loading:
		return false
	if not Supabase.is_authenticated():
		_fail("Debes iniciar sesión para cargar progreso remoto.")
		return false
	pending_user_id = Supabase.get_current_user_id()
	if pending_user_id.is_empty():
		_fail("No se pudo identificar al usuario autenticado.")
		return false
	loading = true
	pending_operation = "select"
	var query := "?user_id=eq." + pending_user_id.uri_encode() + "&select=" + SELECT_FIELDS + "&limit=1"
	var error := http_request.request(
		Supabase.get_rest_url(RESOURCE) + query,
		Supabase.get_authenticated_headers(),
		HTTPClient.METHOD_GET
	)
	if error != OK:
		_fail("No se pudo iniciar la carga del progreso.")
		return false
	return true

func has_loaded_progress() -> bool:
	return not current_progress.is_empty()

func get_current_progress() -> Dictionary:
	return current_progress.duplicate(true)

func clear_progress() -> void:
	current_progress = {}

func _create_initial_progress() -> void:
	pending_operation = "insert"
	var headers := Supabase.get_authenticated_headers(PackedStringArray(["Prefer: return=representation"]))
	var error := http_request.request(
		Supabase.get_rest_url(RESOURCE) + "?select=" + SELECT_FIELDS,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify({"user_id": pending_user_id})
	)
	if error != OK:
		_fail("No se pudo crear el progreso inicial.")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not Supabase.is_authenticated() or Supabase.get_current_user_id() != pending_user_id:
		_fail("La sesión cambió mientras se cargaba el progreso.")
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Error de red al comunicarse con Supabase.")
		return
	if response_code == 401:
		_fail("La sesión ya no es válida. Vuelve a iniciar sesión.")
		return
	if response_code == 403:
		_fail("No tienes permiso para acceder a este progreso.")
		return
	if response_code < 200 or response_code >= 300:
		_fail("Supabase no pudo completar la operación de progreso.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_ARRAY:
		_fail("Supabase devolvió una respuesta de progreso inválida.")
		return
	if pending_operation == "select" and data.is_empty():
		_create_initial_progress()
		return
	if data.is_empty() or typeof(data[0]) != TYPE_DICTIONARY:
		_fail("No se recibió una fila de progreso válida.")
		return
	_complete(data[0])

func _complete(progress: Dictionary) -> void:
	current_progress = progress.duplicate(true)
	loading = false
	pending_operation = ""
	pending_user_id = ""
	progress_loaded.emit(get_current_progress())

func _fail(message: String) -> void:
	loading = false
	pending_operation = ""
	pending_user_id = ""
	progress_load_failed.emit(message)
