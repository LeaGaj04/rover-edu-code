extends Node

# Identificador estable del objetivo actual
var objective_id: String = "recolectar_primer_mineral"
var objective_completed: bool = false

# Función para que el juego evalúe si la meta se cumplió
func evaluar_objetivo(minerales_recolectados: int) -> void:
	if objective_id == "recolectar_primer_mineral" and minerales_recolectados >= 1:
		objective_completed = true
