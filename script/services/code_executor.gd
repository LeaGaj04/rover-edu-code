extends Node

signal ejecucion_iniciada(codigo: String)
signal linea_iniciada(numero: int, contenido: String)
signal linea_finalizada(numero: int, contenido: String)
signal error_detectado(error: Dictionary)
signal ejecucion_finalizada(resultado: Dictionary)

var ejecutando: bool = false
var _tiempo_inicio_msec : float = 0.0


func ejecutar_codigo(
	codigo: String,
	ejecutar_comando: Callable,
	evaluar_condicion: Callable = Callable()
) -> Dictionary:
	_tiempo_inicio_msec = Time.get_ticks_msec()
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

	var compilacion: Dictionary = compilar_programa(codigo)

	if not compilacion["ok"]:
		var error: Dictionary = compilacion["error"]

		resultado["error_type"] = error["type"]
		resultado["error_message"] = error["message"]
		resultado["errors"].append(error)

		error_detectado.emit(error)
		_finalizar(resultado)
		return resultado

	var instrucciones: Array = compilacion["instrucciones"]
	if "for " in codigo:
		resultado["loop_count"] = 1

		for instruccion in instrucciones:
			resultado["loop_iterations"] = maxi(
				resultado["loop_iterations"],
				int(instruccion.get("loop_iteration", 0))
			)

	for instruccion in instrucciones:
		var tipo: String = instruccion.get("tipo", "comando")

		if tipo == "if":
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			linea_iniciada.emit(num_linea, cont_linea)

			var cumple_condicion: bool = false
			if evaluar_condicion.is_valid():
				cumple_condicion = await evaluar_condicion.call(instruccion["condition"])

			if instruccion.get("inverted", false):
				cumple_condicion = not cumple_condicion

			resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1

			if cumple_condicion:
				resultado["if_branch_taken"] = true
				for sub_instruccion in instruccion.get("cuerpo", []):
					var res_sub: Dictionary = await _ejecutar_instruccion_simple(
						sub_instruccion,
						ejecutar_comando,
						resultado
					)
					if not res_sub.get("ok", false):
						_finalizar(resultado)
						return resultado

			linea_finalizada.emit(num_linea, cont_linea)
			continue

		var res_cmd: Dictionary = await _ejecutar_instruccion_simple(
			instruccion,
			ejecutar_comando,
			resultado
		)
		if not res_cmd.get("ok", false):
			_finalizar(resultado)
			return resultado

	resultado["success"] = true
	_finalizar(resultado)
	return resultado


func _ejecutar_instruccion_simple(
	instruccion: Dictionary,
	ejecutar_comando: Callable,
	resultado: Dictionary
) -> Dictionary:
	var numero_linea: int = instruccion["numero"]
	var contenido: String = instruccion["contenido"]
	linea_iniciada.emit(numero_linea, contenido)
	var resultado_comando: Dictionary = await ejecutar_comando.call(
		instruccion["command"],
		instruccion["steps"]
	)
	resultado["commands_used"].append(instruccion["command"])
	resultado["commands_data"].append({
		"command": instruccion["command"],
		"steps": instruccion["steps"]
	})
	resultado["command_count"] += 1
	resultado["movement_count"] += int(resultado_comando.get("steps_completed", 0))
	var recolectados: int = int(resultado_comando.get("minerals_collected", 0))
	var transferidos: int = int(resultado_comando.get("minerals_transferred", 0))
	resultado["minerals_collected"] += recolectados
	resultado["minerals_transferred"] += transferidos
	if int(instruccion.get("loop_iteration", 0)) > 0:
		resultado["loop_minerals_collected"] += recolectados
	if not resultado_comando.get("ok", false):
		var error_comando := {
			"type": resultado_comando.get("error_type", "ejecucion"),
			"line": numero_linea,
			"content": contenido,
			"message": resultado_comando.get("message", "El comando no pudo completarse.")
		}
		resultado["error_type"] = error_comando["type"]
		resultado["error_message"] = error_comando["message"]
		resultado["errors"].append(error_comando)
		error_detectado.emit(error_comando)
	linea_finalizada.emit(numero_linea, contenido)
	return resultado_comando

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

func compilar_programa(codigo: String) -> Dictionary:
	var instrucciones: Array = []
	var lineas := codigo.split("\n")
	var indice := 0

	while indice < lineas.size():
		var linea_original: String = lineas[indice]
		var contenido := linea_original.strip_edges()
		var numero_linea := indice + 1

		if contenido.is_empty():
			indice += 1
			continue

		if contenido.begins_with("if "):
			var resultado_if: Dictionary = _analizar_if(contenido, numero_linea)
			if not resultado_if["ok"]:
				return resultado_if
			var cuerpo_if: Array = []
			indice += 1
			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]
				if linea_cuerpo.strip_edges().is_empty():
					indice += 1
					continue
				var tiene_sangria := (
					linea_cuerpo.begins_with("\t")
					or linea_cuerpo.begins_with("    ")
				)
				if not tiene_sangria:
					break
				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var analisis: Dictionary = analizar_linea(contenido_cuerpo, indice + 1)
				if not analisis["ok"]:
					return analisis
				cuerpo_if.append({
					"tipo": "comando",
					"numero": indice + 1,
					"contenido": contenido_cuerpo,
					"command": analisis["command"],
					"steps": analisis["steps"]
				})
				indice += 1
			if cuerpo_if.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El condicional if necesita al menos una instrucción con sangría."
				)
			instrucciones.append({
				"tipo": "if",
				"numero": numero_linea,
				"contenido": contenido,
				"condition": resultado_if["condition"],
				"inverted": resultado_if["inverted"],
				"cuerpo": cuerpo_if
			})
			continue

		if contenido.begins_with("for "):
			var resultado_for: Dictionary = _analizar_for(
				contenido,
				numero_linea
			)

			if not resultado_for["ok"]:
				return resultado_for

			var repeticiones: int = resultado_for["repeticiones"]
			var cuerpo: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]

				if linea_cuerpo.strip_edges().is_empty():
					indice += 1
					continue

				var tiene_sangria := (
					linea_cuerpo.begins_with("\t")
					or linea_cuerpo.begins_with("    ")
				)

				if not tiene_sangria:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var analisis: Dictionary = analizar_linea(
					contenido_cuerpo,
					indice + 1
				)

				if not analisis["ok"]:
					return analisis

				cuerpo.append({
					"numero": indice + 1,
					"contenido": contenido_cuerpo,
					"command": analisis["command"],
					"steps": analisis["steps"]
				})

				indice += 1

			if cuerpo.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle necesita al menos una instrucción con sangría."
				)

			for iteracion in range(repeticiones):
				for instruccion in cuerpo:
					var copia: Dictionary = instruccion.duplicate()
					copia["loop_iteration"] = iteracion + 1
					instrucciones.append(copia)

			continue

		var analisis: Dictionary = analizar_linea(
			contenido,
			numero_linea
		)

		if not analisis["ok"]:
			return analisis

		instrucciones.append({
			"numero": numero_linea,
			"contenido": contenido,
			"command": analisis["command"],
			"steps": analisis["steps"],
			"loop_iteration": 0
		})

		indice += 1

	return {
		"ok": true,
		"instrucciones": instrucciones
	}

func _analizar_for(
	contenido: String,
	numero_linea: int
) -> Dictionary:
	var expresion := RegEx.new()
	var patron := (
		"^for\\s+([A-Za-z_][A-Za-z0-9_]*)"
		+ "\\s+in\\s+range\\((\\d+)\\):$"
	)

	if expresion.compile(patron) != OK:
		return _error_de_linea(
			numero_linea,
			contenido,
			"No se pudo preparar el analizador del bucle."
		)

	var coincidencia := expresion.search(contenido)

	if coincidencia == null:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Usa el formato: for ciclo in range(10):"
		)

	var repeticiones := int(coincidencia.get_string(2))

	if repeticiones <= 0:
		return _error_de_linea(
			numero_linea,
			contenido,
			"range() debe contener un número mayor que cero."
		)

	if repeticiones > 50:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Por seguridad, el bucle no puede superar 50 repeticiones."
		)

	return {
		"ok": true,
		"repeticiones": repeticiones
	}

func _analizar_if(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.ends_with(":"):
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el carácter de dos puntos ':' al final del condicional if."
		)
	var condicion := contenido.substr(3, contenido.length() - 4).strip_edges()
	var invertido := false
	if condicion.begins_with("not "):
		invertido = true
		condicion = condicion.substr(4).strip_edges()
	# Aceptamos tanto "rover.hay_mineral()" como "hay_mineral()"
	if condicion == "rover.hay_mineral()" or condicion == "hay_mineral()":
		return {
			"ok": true,
			"condition": "rover.hay_mineral()",
			"inverted": invertido
		}
	if condicion in ["rover.hay_mineral", "hay_mineral"]:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Te faltaron los paréntesis de la función: usa 'if rover.hay_mineral():'"
		)
	return _error_de_linea(
		numero_linea,
		contenido,
		"Condición no reconocida. Sensor disponible: rover.hay_mineral()"
	)

func _crear_resultado(codigo: String) -> Dictionary:
	return {
		"code": codigo,
		"success": false,
		"error_type": "",
		"error_message": "",
		"errors": [],
		"commands_used": [],
		"commands_data": [],
		"command_count": 0,
		"movement_count": 0,
		"loop_count": 0,
		"loop_iterations": 0,
		"minerals_collected": 0,
		"minerals_transferred": 0,
		"loop_minerals_collected": 0,
		"duration_seconds": 0.0,
		"objective_id": MissionService.objective_id,
		"objective_completed": MissionService.objective_completed
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
	resultado["duration_seconds"] = (
		Time.get_ticks_msec() - _tiempo_inicio_msec
	) / 1000.0

	# Captura el estado real después de ejecutar todos los comandos.
	MissionService.evaluar_programa(resultado)
	resultado["objective_id"] = MissionService.objective_id
	resultado["objective_completed"] = MissionService.objective_completed

	ejecutando = false

	print(
		"Misión: ",
		resultado["objective_id"],
		" | Completada: ",
		resultado["objective_completed"]
	)

	ejecucion_finalizada.emit(resultado)
