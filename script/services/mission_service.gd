extends Node

signal mision_iniciada(mision_id: String)
signal objetivo_actualizado(mision_id: String, objetivo: String)
signal mision_completada(mision_id: String)
signal conocimiento_desbloqueado(conocimiento_id: String)

enum EstadoMision {
	SIN_INICIAR,
	BUSCAR_MINERAL,
	TRANSFERIR_MINERAL,
	COMPLETADA,
	COMPRAR_CASILLAS,
	CICLO_RECOLECCION,
}

var objective_id: String = "recolectar_primer_mineral"
var objective_completed: bool = false
var estado_actual: EstadoMision = EstadoMision.SIN_INICIAR

var completed_missions: Array = []
var unlocked_knowledge: Array = [
	"objeto",
	"metodo"
]


func _ready() -> void:
	iniciar_mision()


func iniciar_mision() -> void:
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"Encuentra una muestra y ejecuta rover.minar()."
	)
	
func iniciar_ruta_calibracion() -> void:
	objective_id = "ruta_calibracion"
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL

	mision_iniciada.emit(objective_id)

	objetivo_actualizado.emit(
		objective_id,
		"RUTA DE CALIBRACION\n" +
		"Programa una secuencia para avanzar al mineral, " +
        "extraerlo, regresar a la casilla inicial y transferirlo."
	)

	print("Mision iniciada: ruta_calibracion")


func reiniciar_mision() -> void:
	iniciar_mision()


func preparar_mision_expansion() -> void:
	if not objective_completed:
		return

	if objective_id == "ruta_calibracion":
		iniciar_ciclo_recoleccion()
		return

	if objective_id != "ciclo_recoleccion":
		return

	objective_id = "comprar_casillas"
	objective_completed = "comprar_casillas" in completed_missions
	estado_actual = (
		EstadoMision.COMPLETADA
		if objective_completed
		else EstadoMision.COMPRAR_CASILLAS
	)

	mision_iniciada.emit(objective_id)


func registrar_compra_casillas() -> void:
	if objective_id != "comprar_casillas" or objective_completed:
		return
	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA
	completed_missions.append(objective_id)
	mision_completada.emit(objective_id)


func evaluar_objetivo(minerales_recolectados: int) -> void:
	registrar_mineral_recolectado(minerales_recolectados)


func registrar_mineral_recolectado(cantidad: int) -> void:
	if estado_actual != EstadoMision.BUSCAR_MINERAL:
		return

	if cantidad <= 0:
		return

	estado_actual = EstadoMision.TRANSFERIR_MINERAL

	objetivo_actualizado.emit(
		objective_id,
		"Buen trabajo. La muestra fue extraida correctamente. " +
		"Progreso 1 de 2: ahora ejecuta rover.transferir() " +
		"para enviarla a la nave."
	)

	print("Mision actualizada: transferir el mineral.")


func registrar_transferencia(cantidad: int) -> void:
	if estado_actual != EstadoMision.TRANSFERIR_MINERAL:
		return

	if cantidad <= 0:
		
		return
	if objective_id == "ruta_calibracion":
		
		return

	estado_actual = EstadoMision.COMPLETADA
	objective_completed = true

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	desbloquear_conocimiento("secuencia")

	mision_completada.emit(objective_id)

	print("Mision completada: ", objective_id)
	print("Conocimiento desbloqueado: secuencia")


func desbloquear_conocimiento(conocimiento_id: String) -> void:
	if conocimiento_id in unlocked_knowledge:
		return

	unlocked_knowledge.append(conocimiento_id)
	conocimiento_desbloqueado.emit(conocimiento_id)
	
func aplicar_progreso(progress: Dictionary) -> void:
	objective_id = str(
		progress.get(
			"current_mission_id",
			"recolectar_primer_mineral"
		)
	)
	
	var misiones_guardadas = progress.get(
		"completed_missions",
		[]
	)

	if typeof(misiones_guardadas) == TYPE_ARRAY:
		completed_missions = misiones_guardadas.duplicate()
	else:
		completed_missions = []

	var conocimientos_guardados = progress.get(
		"unlocked_knowledge",
		["objeto", "metodo"]
	)

	if typeof(conocimientos_guardados) == TYPE_ARRAY:
		unlocked_knowledge = conocimientos_guardados.duplicate()
	else:
		unlocked_knowledge = [
			"objeto",
			"metodo"
		]

		# Adapta las partidas que llegaron al antiguo objetivo de compra,
	# siempre que todavía conserven el corredor sin expandir.
	if (
		objective_id == "comprar_casillas"
		and "ruta_calibracion" in completed_missions
		and "ciclo_recoleccion" not in completed_missions
		and "comprar_casillas" not in completed_missions
		and int(progress.get("map_tier", 0)) == 1
	):
		objective_id = "ciclo_recoleccion"

	if (
		"ruta_calibracion" in completed_missions
		or objective_id == "ciclo_recoleccion"
	):
		desbloquear_modulo_for()

	objective_completed = objective_id in completed_missions
	preparar_mision_expansion()

	if objective_id == "ciclo_recoleccion":
		estado_actual = EstadoMision.CICLO_RECOLECCION
		return
	if objective_id == "comprar_casillas":
		estado_actual = EstadoMision.COMPLETADA if objective_completed else EstadoMision.COMPRAR_CASILLAS
		return
	if (
		objective_id == "recolectar_primer_mineral"
		and objective_completed
		and int(progress.get("map_tier", 0)) >= 1
	):
		iniciar_ruta_calibracion()
		return
	if objective_completed:
		estado_actual = EstadoMision.COMPLETADA
	elif int(progress.get("minerals_rover", 0)) > 0:
		# Permite continuar si el jugador cerró el juego después de minar.
		estado_actual = EstadoMision.TRANSFERIR_MINERAL
	else:
		estado_actual = EstadoMision.BUSCAR_MINERAL

	print(
		"Progreso de misión cargado: ",
		objective_id,
		" | Completada: ",
		objective_completed
	)


func get_objetivo_actual() -> String:
	if objective_completed:
		return "Misión completada."

	if objective_id == "ciclo_recoleccion":
		return (
			"CICLO DE RECOLECCIÓN\n" +
			"Un bucle for repite las instrucciones con sangría. " +
			"Por ejemplo, for ciclo in range(2): repite su bloque dos veces.\n" +
			"Tu desafío: recoger 10 minerales usando for y transferirlos " +
			"una sola vez al final, en un mismo programa. " +
			"La transferencia debe quedar fuera del bloque.\n" +
			"Empieza en el centro con el inventario del rover vacío."
		)

	if objective_id == "comprar_casillas":
		return (
			"Automatización completada. Compra +3 CASILLAS " +
			"en Mejoras utilizando 10 minerales de la nave."
		)

	if objective_id == "ruta_calibracion":
		return (
			"Ejecuta norte, minar, sur y transferir " +
			"una sola vez, en ese orden y en un mismo programa."
		)

	match estado_actual:
		EstadoMision.BUSCAR_MINERAL:
			return "Minar la primera muestra."
		EstadoMision.TRANSFERIR_MINERAL:
			return "Transferir la primera muestra."
		_:
			return "Misión sin iniciar."


func get_completed_missions() -> Array:
	return completed_missions.duplicate()


func get_unlocked_knowledge() -> Array:
	return unlocked_knowledge.duplicate()

func evaluar_programa(resultado: Dictionary) -> void:
	if objective_completed:
		return

	if not resultado.get("success", false):
		return

	if objective_id == "ciclo_recoleccion":
		_evaluar_ciclo_recoleccion(resultado)
		return

	if objective_id != "ruta_calibracion":
		return

	var comandos: Array = resultado.get("commands_used", [])
	var secuencia_esperada: Array = [
		"norte",
		"minar",
		"sur",
		"transferir"
	]

	if comandos == secuencia_esperada:
		estado_actual = EstadoMision.COMPLETADA
		objective_completed = true

		if objective_id not in completed_missions:
			completed_missions.append(objective_id)

		mision_completada.emit(objective_id)
		print("Misión completada con la secuencia correcta.")
		return

	if "transferir" in comandos:
		estado_actual = EstadoMision.BUSCAR_MINERAL
		objetivo_actualizado.emit(
			objective_id,
			"Para calibrar, ejecuta una sola vez y en este orden: " +
			"norte, minar, sur y transferir, dentro del mismo programa."
		)


func _evaluar_ciclo_recoleccion(resultado: Dictionary) -> void:
	var comandos: Array = resultado.get("commands_used", [])
	var recolectados: int = int(
		resultado.get("minerals_collected", 0)
	)
	var transferidos: int = int(
		resultado.get("minerals_transferred", 0)
	)
	var recogidos_en_bucle: int = int(
		resultado.get("loop_minerals_collected", 0)
	)

	var termina_transfiriendo: bool = false
	if not comandos.is_empty():
		termina_transfiriendo = comandos.back() == "transferir"

	var cumple_objetivo: bool = (
		int(resultado.get("loop_count", 0)) > 0
		and recolectados == 10
		and recogidos_en_bucle == 10
		and transferidos == 10
		and comandos.count("transferir") == 1
		and termina_transfiriendo
	)

	if not cumple_objetivo:
		objetivo_actualizado.emit(
			objective_id,
			"Programa terminado. Recogiste %d/10 minerales dentro del bucle " %
			recogidos_en_bucle +
			"y transferiste %d/10. " % transferidos +
			"El desafío requiere recoger los diez usando for y " +
			"transferirlos una sola vez al final del mismo programa. " +
			"Antes de reintentar, vacía el inventario en la casilla inicial."
		)
		return

	objective_completed = true
	estado_actual = EstadoMision.COMPLETADA

	if objective_id not in completed_missions:
		completed_missions.append(objective_id)

	mision_completada.emit(objective_id)
	print("Ciclo de recolección completado.")
	
func desbloquear_modulo_for() -> void:
	GestorSintaxis.desbloquear_sintaxis("for")
	GestorSintaxis.desbloquear_sintaxis("in range")
	desbloquear_conocimiento("bucle_for")


func iniciar_ciclo_recoleccion() -> void:
	objective_id = "ciclo_recoleccion"
	objective_completed = false
	estado_actual = EstadoMision.CICLO_RECOLECCION

	desbloquear_modulo_for()
	mision_iniciada.emit(objective_id)

	print("Misión iniciada: ciclo_recoleccion")
