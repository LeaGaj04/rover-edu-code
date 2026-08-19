extends Node

const SUPABASE_URL := "https://ulivinilxszdyazignbi.supabase.co"
const SUPABASE_KEY := "sb_publishable_Nk8m4AZRU1ffH6gJCF45pw_KI-H6-LK"

var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(_on_request_completed)

	test_connection()


func test_connection() -> void:
	var headers := PackedStringArray([
		"apikey: " + SUPABASE_KEY,
		"Accept: application/json"
	])

	var error := http_request.request(
		SUPABASE_URL + "/rest/v1/connection_test?select=*",
		headers,
		HTTPClient.METHOD_GET
	)

	if error != OK:
		print("❌ No se pudo iniciar la petición a Supabase.")
		print("Error Godot: ", error)

func _on_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	print("Código HTTP: ", response_code)

	var response_text := body.get_string_from_utf8()

	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("✅ EduCode conectado correctamente a Supabase.")
		print("Respuesta: ", response_text)
	else:
		print("❌ Error conectando con Supabase.")
		print("Respuesta: ", response_text)
