extends Node

signal ejecucion_iniciada(codigo: String)
signal linea_iniciada(numero: int, contenido: String)
signal linea_finalizada(numero: int, contenido: String)
signal error_detectado(error: Dictionary)
signal ejecucion_finalizada(resultado: Dictionary)

var ejecutando: bool = false


func ejecutar_codigo(
	codigo: String,
	ejecutar_comando: Callable
) -> Dictionary:
	var resultado := _crear_resultado(codigo)

	if ejecutando:
		resultado["error_type"] = "ejecucion"
		resultado["error_message"] = "Ya existe un programa en ejecución."
		return resultado

	ejecutando = true
	ejecucion_iniciada.emit(codigo)

	if not GestorSintaxis.validar_codigo(codigo):
		resultado["error_type"] = "sintaxis_bloqueada"
		resultado["error_message"] = (
			"El código utiliza una estructura que todavía no está desbloqueada."
		)
		resultado["errors"].append({
			"type": resultado["error_type"],
			"line": 0,
			"message": resultado["error_message"]
		})

		error_detectado.emit(resultado["errors"][0])
		_finalizar(resultado)
		return resultado

	var lineas := codigo.split("\n")

	for indice in range(lineas.size()):
		var numero_linea := indice + 1
		var contenido := lineas[indice].strip_edges()

		if contenido.is_empty():
			continue

		var analisis := analizar_linea(contenido, numero_linea)

		if not analisis["ok"]:
			resultado["error_type"] = analisis["error"]["type"]
			resultado["error_message"] = analisis["error"]["message"]
			resultado["errors"].append(analisis["error"])

			error_detectado.emit(analisis["error"])
			_finalizar(resultado)
			return resultado

		linea_iniciada.emit(numero_linea, contenido)

		var resultado_comando: Dictionary = await ejecutar_comando.call(
			analisis["command"],
			analisis["steps"]
		)

		resultado["commands_used"].append(analisis["command"])
		resultado["command_count"] += 1
		resultado["movement_count"] += int(
			resultado_comando.get("steps_completed", 0)
		)

		if not resultado_comando.get("ok", false):
			var error_comando := {
				"type": resultado_comando.get(
					"error_type",
					"ejecucion"
				),
				"line": numero_linea,
				"content": contenido,
				"message": resultado_comando.get(
					"message",
					"El comando no pudo completarse."
				)
			}

			resultado["error_type"] = error_comando["type"]
			resultado["error_message"] = error_comando["message"]
			resultado["errors"].append(error_comando)

			error_detectado.emit(error_comando)
			_finalizar(resultado)
			return resultado

		linea_finalizada.emit(numero_linea, contenido)

	resultado["success"] = true
	_finalizar(resultado)
	return resultado


func analizar_linea(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.begins_with("rover."):
		return _error_de_linea(
			numero_linea,
			contenido,
			"La instrucción debe comenzar con 'rover.'."
		)

	var posicion_punto := contenido.find(".")
	var posicion_parentesis_izquierdo := contenido.find("(")
	var posicion_parentesis_derecho := contenido.rfind(")")

	if posicion_parentesis_izquierdo == -1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el paréntesis de apertura."
		)

	if posicion_parentesis_derecho == -1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el paréntesis de cierre."
		)

	if posicion_parentesis_derecho != contenido.length() - 1:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Hay contenido después del paréntesis de cierre."
		)

	var comando := contenido.substr(
		posicion_punto + 1,
		posicion_parentesis_izquierdo - posicion_punto - 1
	).strip_edges()

	var comandos_validos := [
		"norte",
		"sur",
		"este",
		"oeste",
		"minar",
		"transferir"
	]

	if comando not in comandos_validos:
		return _error_de_linea(
			numero_linea,
			contenido,
			"El rover no conoce el comando '" + comando + "'."
		)

	var argumento := contenido.substr(
		posicion_parentesis_izquierdo + 1,
		posicion_parentesis_derecho - posicion_parentesis_izquierdo - 1
	).strip_edges()

	var pasos := 1

	if not argumento.is_empty():
		if not argumento.is_valid_int():
			return _error_de_linea(
				numero_linea,
				contenido,
				"El parámetro debe ser un número entero."
			)

		pasos = int(argumento)

		if pasos <= 0:
			return _error_de_linea(
				numero_linea,
				contenido,
				"La cantidad de pasos debe ser mayor que cero."
			)

	if comando in ["minar", "transferir"] and not argumento.is_empty():
		return _error_de_linea(
			numero_linea,
			contenido,
			"El comando '" + comando + "' no recibe parámetros."
		)

	return {
		"ok": true,
		"command": comando,
		"steps": pasos
	}


func _crear_resultado(codigo: String) -> Dictionary:
	return {
		"code": codigo,
		"success": false,
		"error_type": "",
		"error_message": "",
		"errors": [],
		"commands_used": [],
		"command_count": 0,
		"movement_count": 0
	}


func _error_de_linea(
	numero: int,
	contenido: String,
	mensaje: String
) -> Dictionary:
	return {
		"ok": false,
		"error": {
			"type": "sintaxis",
			"line": numero,
			"content": contenido,
			"message": mensaje
		}
	}


func _finalizar(resultado: Dictionary) -> void:
	ejecutando = false
	ejecucion_finalizada.emit(resultado)
