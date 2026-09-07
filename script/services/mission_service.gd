extends Node

signal mision_iniciada(mision_id: String)
signal objetivo_actualizado(mision_id: String, objetivo: String)
signal mision_completada(mision_id: String)

enum EstadoMision {
	SIN_INICIAR,
	BUSCAR_MINERAL,
	TRANSFERIR_MINERAL,
	COMPLETADA,
}

# Primera mision educativa: minar una muestra y llevarla a la base.
var objective_id: String = "recolectar_primer_mineral"
var objective_completed: bool = false
var estado_actual: EstadoMision = EstadoMision.SIN_INICIAR


func _ready() -> void:
	iniciar_mision()


func iniciar_mision() -> void:
	objective_completed = false
	estado_actual = EstadoMision.BUSCAR_MINERAL
	mision_iniciada.emit(objective_id)
	objetivo_actualizado.emit(
		objective_id,
		"Encuentra una casilla con mineral y ejecuta rover.minar()."
	)


func reiniciar_mision() -> void:
	iniciar_mision()


# Conserva la llamada que ya realiza rover.gd.
func evaluar_objetivo(minerales_recolectados: int) -> void:
	registrar_mineral_recolectado(minerales_recolectados)


func registrar_mineral_recolectado(cantidad: int) -> void:
	if estado_actual != EstadoMision.BUSCAR_MINERAL or cantidad <= 0:
		return

	estado_actual = EstadoMision.TRANSFERIR_MINERAL
	objetivo_actualizado.emit(
		objective_id,
		"Buen trabajo. La muestra fue extraida correctamente. Progreso 1 de 2: " +
		"ahora ejecuta rover.transferir() para enviarla a la nave."
	)
	print("Mision actualizada: transferir el mineral.")


# Esta funcion se conectara a la transferencia en el siguiente paso.
func registrar_transferencia(cantidad: int) -> void:
	if estado_actual != EstadoMision.TRANSFERIR_MINERAL or cantidad <= 0:
		return

	estado_actual = EstadoMision.COMPLETADA
	objective_completed = true
	mision_completada.emit(objective_id)
	print("Mision completada: ", objective_id)


func get_objetivo_actual() -> String:
	match estado_actual:
		EstadoMision.BUSCAR_MINERAL:
			return "Minar la primera muestra."
		EstadoMision.TRANSFERIR_MINERAL:
			return "Transferir la primera muestra."
		EstadoMision.COMPLETADA:
			return "Mision completada."
		_:
			return "Mision sin iniciar."
