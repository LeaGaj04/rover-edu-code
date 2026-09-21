extends Node

signal ejecucion_iniciada(codigo: String)
signal linea_iniciada(numero: int, contenido: String)
signal linea_finalizada(numero: int, contenido: String)
signal error_detectado(error: Dictionary)
signal ejecucion_finalizada(resultado: Dictionary)
signal progreso_actualizado(resultado: Dictionary)
signal paso_esperando(numero: int, contenido: String)
signal _avanzar_paso_solicitado

var ejecutando: bool = false
var detener_solicitado: bool = false
var modo_paso_a_paso: bool = false
var esperando_paso: bool = false
var _tiempo_inicio_msec : float = 0.0
var _objective_id_at_start: String = ""
var _objective_completed_at_start: bool = false

func detener_ejecucion() -> void:
	if ejecutando:
		detener_solicitado = true
		if esperando_paso:
			_avanzar_paso_solicitado.emit()

func avanzar_un_paso() -> void:
	if ejecutando and esperando_paso:
		_avanzar_paso_solicitado.emit()

func continuar_todo() -> void:
	if ejecutando:
		modo_paso_a_paso = false
		if esperando_paso:
			_avanzar_paso_solicitado.emit()

func _esperar_paso_si_aplica(numero: int, contenido: String) -> void:
	if modo_paso_a_paso and not detener_solicitado:
		esperando_paso = true
		paso_esperando.emit(numero, contenido)
		await _avanzar_paso_solicitado
		esperando_paso = false

func ejecutar_codigo(
	codigo: String,
	ejecutar_comando: Callable,
	evaluar_condicion: Callable = Callable(),
	paso_a_paso: bool = false
) -> Dictionary:
	_tiempo_inicio_msec = Time.get_ticks_msec()
	var resultado := _crear_resultado(codigo)

	if ejecutando:
		resultado["error_type"] = "ejecucion"
		resultado["error_message"] = "Ya existe un programa en ejecución."
		return resultado

	_objective_id_at_start = MissionService.objective_id
	_objective_completed_at_start = (
		MissionService.objective_completed
		or _objective_id_at_start in MissionService.get_completed_missions()
	)
	resultado["objective_id"] = _objective_id_at_start
	resultado["objective_completed"] = false

	ejecutando = true
	detener_solicitado = false
	modo_paso_a_paso = paso_a_paso
	esperando_paso = false
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
			await _esperar_paso_si_aplica(num_linea, cont_linea)
			if detener_solicitado:
				linea_finalizada.emit(num_linea, cont_linea)
				break

			var cumple_condicion: bool = false
			if evaluar_condicion.is_valid():
				cumple_condicion = await evaluar_condicion.call(instruccion["condition"])

			if instruccion.get("inverted", false):
				cumple_condicion = not cumple_condicion

			resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1

			if cumple_condicion:
				resultado["if_branch_taken"] = true
				for sub_instruccion in instruccion.get("cuerpo", []):
					if detener_solicitado:
						break
					if int(instruccion.get("loop_iteration", 0)) > 0:
						sub_instruccion["loop_iteration"] = instruccion["loop_iteration"]
					var res_sub: Dictionary = await _ejecutar_instruccion_simple(
						sub_instruccion,
						ejecutar_comando,
						resultado
					)
					if not res_sub.get("ok", false):
						_finalizar(resultado)
						return resultado

			linea_finalizada.emit(num_linea, cont_linea)
			if detener_solicitado:
				break
			continue

		if tipo == "while":
			var num_linea: int = instruccion["numero"]
			var cont_linea: String = instruccion["contenido"]
			var condicion: String = instruccion["condition"]
			var invertido: bool = instruccion.get("inverted", false)
			var cuerpo_while: Array = instruccion.get("cuerpo", [])
			const MAX_WHILE_ITER: int = 50
			var iteracion: int = 0
			resultado["loop_count"] = maxi(int(resultado.get("loop_count", 0)), 1)
			while true:
				if detener_solicitado:
					break
				iteracion += 1
				if iteracion > MAX_WHILE_ITER:
					var err_infinito := {
						"type": "ejecucion",
						"line": num_linea,
						"content": cont_linea,
						"message": "Límite de seguridad alcanzado: el bucle while superó 50 iteraciones para prevenir un bucle infinito."
					}
					resultado["error_type"] = err_infinito["type"]
					resultado["error_message"] = err_infinito["message"]
					resultado["errors"].append(err_infinito)
					error_detectado.emit(err_infinito)
					_finalizar(resultado)
					return resultado
				linea_iniciada.emit(num_linea, cont_linea)
				await _esperar_paso_si_aplica(num_linea, cont_linea)
				if detener_solicitado:
					linea_finalizada.emit(num_linea, cont_linea)
					break
				var cumple: bool = false
				if evaluar_condicion.is_valid():
					cumple = await evaluar_condicion.call(condicion)
				if invertido:
					cumple = not cumple
				linea_finalizada.emit(num_linea, cont_linea)
				if not cumple:
					break
				resultado["loop_iterations"] = maxi(int(resultado.get("loop_iterations", 0)), iteracion)
				for sub_ins in cuerpo_while:
					if detener_solicitado:
						break
					var sub_tipo: String = sub_ins.get("tipo", "comando")
					if sub_tipo == "if":
						var num_if: int = sub_ins["numero"]
						var cont_if: String = sub_ins["contenido"]
						linea_iniciada.emit(num_if, cont_if)
						await _esperar_paso_si_aplica(num_if, cont_if)
						if detener_solicitado:
							linea_finalizada.emit(num_if, cont_if)
							break
						var cumple_if: bool = false
						if evaluar_condicion.is_valid():
							cumple_if = await evaluar_condicion.call(sub_ins["condition"])
						if sub_ins.get("inverted", false):
							cumple_if = not cumple_if
						resultado["if_evaluations"] = resultado.get("if_evaluations", 0) + 1
						if cumple_if:
							resultado["if_branch_taken"] = true
							for cmd_if in sub_ins.get("cuerpo", []):
								if detener_solicitado:
									break
								cmd_if["loop_iteration"] = iteracion
								var res_sub: Dictionary = await _ejecutar_instruccion_simple(
									cmd_if,
									ejecutar_comando,
									resultado
								)
								if not res_sub.get("ok", false):
									_finalizar(resultado)
									return resultado
						linea_finalizada.emit(num_if, cont_if)
						continue
					sub_ins["loop_iteration"] = iteracion
					var res_while_cmd: Dictionary = await _ejecutar_instruccion_simple(
						sub_ins,
						ejecutar_comando,
						resultado
					)
					if not res_while_cmd.get("ok", false):
						_finalizar(resultado)
						return resultado
					if detener_solicitado:
						break

			if detener_solicitado:
				break
			progreso_actualizado.emit(resultado)
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
	var numero_linea: int = int(instruccion.get("numero", 0))
	var contenido: String = str(instruccion.get("contenido", ""))
	var comando: String = str(instruccion.get("command", instruccion.get("comando", "")))
	var pasos: int = int(instruccion.get("steps", 1))

	linea_iniciada.emit(numero_linea, contenido)
	await _esperar_paso_si_aplica(numero_linea, contenido)

	if detener_solicitado:
		linea_finalizada.emit(numero_linea, contenido)
		return {
			"ok": false,
			"error_type": "ejecucion",
			"message": "Ejecución detenida."
		}

	if comando.is_empty():
		linea_finalizada.emit(numero_linea, contenido)
		return {"ok": true}

	var resultado_comando: Dictionary = await ejecutar_comando.call(
		comando,
		pasos
	)
	resultado["commands_used"].append(comando)
	resultado["commands_data"].append({
		"command": comando,
		"steps": pasos
	})
	resultado["command_count"] += 1
	resultado["movement_count"] += int(resultado_comando.get("steps_completed", 0))
	var recolectados: int = int(resultado_comando.get("minerals_collected", 0))
	var transferidos: int = int(resultado_comando.get("minerals_transferred", 0))
	resultado["minerals_collected"] += recolectados
	resultado["minerals_transferred"] += transferidos
	if (
		_objective_id_at_start == "trabajo_continuo"
		and int(resultado.get("minerals_transferred", 0)) >= 2
	):
		detener_solicitado = true
	elif (
		_objective_id_at_start in ["ciclo_autonomo", "exploracion_3x3"]
		and int(resultado.get("minerals_transferred", 0)) >= 3
	):
		detener_solicitado = true
	elif (
		_objective_id_at_start == "ciclo_recoleccion"
		and int(resultado.get("minerals_transferred", 0)) >= 2
	):
		detener_solicitado = true
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

func _contar_espacios_sangria(linea: String) -> int:
	var espacios := 0
	for i in range(linea.length()):
		var c := linea[i]
		if c == "\t":
			espacios += 4
		elif c == " ":
			espacios += 1
		else:
			break
	return espacios

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

		var contenido_lower := contenido.to_lower()

		if contenido_lower.begins_with("if "):
			var resultado_if: Dictionary = _analizar_if(contenido, numero_linea)
			if not resultado_if["ok"]:
				return resultado_if

			var sangria_base := _contar_espacios_sangria(linea_original)
			var cuerpo_if: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]
				if linea_cuerpo.strip_edges().is_empty():
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_base:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var analisis_if: Dictionary = analizar_linea(contenido_cuerpo, indice + 1)
				if not analisis_if["ok"]:
					return analisis_if

				cuerpo_if.append({
					"tipo": "comando",
					"numero": indice + 1,
					"contenido": contenido_cuerpo,
					"command": analisis_if["command"],
					"steps": analisis_if["steps"]
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
				"cuerpo": cuerpo_if,
				"loop_iteration": 0
			})
			continue

		if contenido_lower.begins_with("for "):
			var resultado_for: Dictionary = _analizar_for(
				contenido,
				numero_linea
			)

			if not resultado_for["ok"]:
				return resultado_for

			var repeticiones: int = resultado_for["repeticiones"]
			var sangria_for := _contar_espacios_sangria(linea_original)
			var cuerpo_for: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]

				if linea_cuerpo.strip_edges().is_empty():
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_for:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var cont_cuerpo_lower := contenido_cuerpo.to_lower()

				# Caso 1: if anidado dentro de for
				if cont_cuerpo_lower.begins_with("if "):
					var num_linea_if := indice + 1
					var res_if_anidado := _analizar_if(contenido_cuerpo, num_linea_if)
					if not res_if_anidado["ok"]:
						return res_if_anidado

					var sangria_if := sangria_cuerpo
					var cuerpo_if_anidado: Array = []
					indice += 1

					while indice < lineas.size():
						var linea_sub := lineas[indice]
						if linea_sub.strip_edges().is_empty():
							indice += 1
							continue

						var sangria_sub := _contar_espacios_sangria(linea_sub)
						if sangria_sub <= sangria_if:
							break

						var cont_sub := linea_sub.strip_edges()
						var analisis_sub := analizar_linea(cont_sub, indice + 1)
						if not analisis_sub["ok"]:
							return analisis_sub

						cuerpo_if_anidado.append({
							"tipo": "comando",
							"numero": indice + 1,
							"contenido": cont_sub,
							"command": analisis_sub["command"],
							"steps": analisis_sub["steps"]
						})
						indice += 1

					if cuerpo_if_anidado.is_empty():
						return _error_de_linea(
							num_linea_if,
							contenido_cuerpo,
							"El condicional if necesita al menos una instrucción con sangría."
						)

					cuerpo_for.append({
						"tipo": "if",
						"numero": num_linea_if,
						"contenido": contenido_cuerpo,
						"condition": res_if_anidado["condition"],
						"inverted": res_if_anidado["inverted"],
						"cuerpo": cuerpo_if_anidado
					})
					continue

				# Caso 2: comando normal dentro de for
				var analisis_for: Dictionary = analizar_linea(
					contenido_cuerpo,
					indice + 1
				)

				if not analisis_for["ok"]:
					return analisis_for

				cuerpo_for.append({
					"tipo": "comando",
					"numero": indice + 1,
					"contenido": contenido_cuerpo,
					"command": analisis_for["command"],
					"steps": analisis_for["steps"]
				})

				indice += 1

			if cuerpo_for.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle necesita al menos una instrucción con sangría."
				)

			for iteracion in range(repeticiones):
				for instruccion in cuerpo_for:
					var copia: Dictionary = instruccion.duplicate(true)
					copia["loop_iteration"] = iteracion + 1
					instrucciones.append(copia)

			continue

		if contenido_lower.begins_with("while "):
			var resultado_while: Dictionary = _analizar_while(contenido, numero_linea)
			if not resultado_while["ok"]:
				return resultado_while

			var sangria_while := _contar_espacios_sangria(linea_original)
			var cuerpo_while: Array = []
			indice += 1

			while indice < lineas.size():
				var linea_cuerpo: String = lineas[indice]
				if linea_cuerpo.strip_edges().is_empty():
					indice += 1
					continue

				var sangria_cuerpo := _contar_espacios_sangria(linea_cuerpo)
				if sangria_cuerpo <= sangria_while:
					break

				var contenido_cuerpo := linea_cuerpo.strip_edges()
				var cont_cuerpo_lower := contenido_cuerpo.to_lower()

				# Soporte para if anidado dentro de while
				if cont_cuerpo_lower.begins_with("if "):
					var num_linea_if := indice + 1
					var res_if_anidado := _analizar_if(contenido_cuerpo, num_linea_if)
					if not res_if_anidado["ok"]:
						return res_if_anidado

					var sangria_if := sangria_cuerpo
					var cuerpo_if_anidado: Array = []
					indice += 1

					while indice < lineas.size():
						var linea_sub := lineas[indice]
						if linea_sub.strip_edges().is_empty():
							indice += 1
							continue

						var sangria_sub := _contar_espacios_sangria(linea_sub)
						if sangria_sub <= sangria_if:
							break

						var cont_sub := linea_sub.strip_edges()
						var analisis_sub := analizar_linea(cont_sub, indice + 1)
						if not analisis_sub["ok"]:
							return analisis_sub

						cuerpo_if_anidado.append({
							"tipo": "comando",
							"numero": indice + 1,
							"contenido": cont_sub,
							"command": analisis_sub["command"],
							"steps": analisis_sub["steps"]
						})
						indice += 1

					if cuerpo_if_anidado.is_empty():
						return _error_de_linea(
							num_linea_if,
							contenido_cuerpo,
							"El condicional if necesita al menos una instrucción con sangría."
						)

					cuerpo_while.append({
						"tipo": "if",
						"numero": num_linea_if,
						"contenido": contenido_cuerpo,
						"condition": res_if_anidado["condition"],
						"inverted": res_if_anidado["inverted"],
						"cuerpo": cuerpo_if_anidado
					})
					continue

				# Comando regular
				var analisis_cmd: Dictionary = analizar_linea(contenido_cuerpo, indice + 1)
				if not analisis_cmd["ok"]:
					return analisis_cmd

				cuerpo_while.append({
					"tipo": "comando",
					"numero": indice + 1,
					"contenido": contenido_cuerpo,
					"command": analisis_cmd["command"],
					"steps": analisis_cmd["steps"]
				})
				indice += 1

			if cuerpo_while.is_empty():
				return _error_de_linea(
					numero_linea,
					contenido,
					"El bucle while necesita al menos una instrucción con sangría."
				)

			instrucciones.append({
				"tipo": "while",
				"numero": numero_linea,
				"contenido": contenido,
				"condition": resultado_while["condition"],
				"inverted": resultado_while["inverted"],
				"cuerpo": cuerpo_while,
				"loop_iteration": 0
			})
			continue

		var analisis: Dictionary = analizar_linea(
			contenido,
			numero_linea
		)

		if not analisis["ok"]:
			return analisis

		instrucciones.append({
			"tipo": "comando",
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
		"^(?i)for\\s+([A-Za-z_][A-Za-z0-9_]*)"
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
		"objective_completed": false
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
	var completed_missions := MissionService.get_completed_missions()
	var objective_is_completed := (
		(
			MissionService.objective_id == _objective_id_at_start
			and MissionService.objective_completed
		)
		or _objective_id_at_start in completed_missions
	)
	resultado["objective_id"] = _objective_id_at_start
	resultado["objective_completed"] = (
		not _objective_completed_at_start
		and objective_is_completed
	)

	ejecutando = false
	modo_paso_a_paso = false
	esperando_paso = false

	print(
		"Misión: ",
		resultado["objective_id"],
		" | Completada: ",
		resultado["objective_completed"]
	)

	ejecucion_finalizada.emit(resultado)

func _analizar_while(contenido: String, numero_linea: int) -> Dictionary:
	if not contenido.ends_with(":"):
		return _error_de_linea(
			numero_linea,
			contenido,
			"Falta el carácter de dos puntos ':' al final del bucle while."
		)

	var condicion := contenido.substr(5, contenido.length() - 6).strip_edges()
	var invertido := false

	if condicion.begins_with("not ") or condicion.begins_with("NOT "):
		invertido = true
		condicion = condicion.substr(4).strip_edges()

	var condiciones_validas := [
		"True",
		"False",
		"true",
		"false",
		"rover.hay_mineral()",
		"hay_mineral()",
		"rover.tiene_espacio()",
		"tiene_espacio()",
		"rover.en_base()",
		"en_base()"
	]
	
	if condicion in condiciones_validas:
		return {
			"ok": true,
			"condition": condicion,
			"inverted": invertido
		}

	if condicion in ["rover.hay_mineral", "hay_mineral", "rover.tiene_espacio", "tiene_espacio", "rover.en_base", "en_base"]:
		return _error_de_linea(
			numero_linea,
			contenido,
			"Te faltaron los paréntesis '()' en la condición: usa '" + condicion + "()'"
		)

	return _error_de_linea(
		numero_linea,
		contenido,
		"Condición no válida para while. Puedes usar True, False " +
		"o los sensores rover.tiene_espacio(), rover.en_base() " +
		"y rover.hay_mineral()."
	)
