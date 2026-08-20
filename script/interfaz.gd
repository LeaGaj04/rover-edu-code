extends CanvasLayer

@onready var caja_codigo = $TextEdit
@export var mi_rover : CharacterBody3D


func _on_button_pressed() -> void:
	# 1. Obtenemos el texto del usuario
	var texto_usuario = $TextEdit.text 
	
	# 2. El Lexer limpia y separa el texto
	var mi_lexer = Lexer.new()
	var tokens = mi_lexer.tokenizar(texto_usuario)
	
	# 3. EL PARSER: Verificamos si la estructura tiene sentido
	if tokens.size() == 5:
		var es_objeto_rover = tokens[0].valor == "rover"
		var tiene_punto = tokens[1].tipo == Lexer.TipoToken.PUNTO
		var tiene_parentesis = tokens[3].tipo == Lexer.TipoToken.PARENTESIS_IZQ and tokens[4].tipo == Lexer.TipoToken.PARENTESIS_DER
		
		if es_objeto_rover and tiene_punto and tiene_parentesis:
			var comando = tokens[2].valor 
			
			# 4. EL INTÉRPRETE: Movemos el rover
			ejecutar_movimiento_rover(comando)
		else:
			print("Error de Sintaxis A.D.A: Revisa los puntos y paréntesis.")
	else:
		print("Error de Sintaxis A.D.A: Comando incompleto.")


# Esta es la función que ejecuta el movimiento 3D
func ejecutar_movimiento_rover(comando: String):
	# Verificamos que el rover esté conectado para que no dé error
	if mi_rover == null:
		print("Error: El Rover no está asignado en el Inspector.")
		return
		
	if comando == "avanzar":
		print("El rover avanza")
		mi_rover.avanzar()  # <-- LE DAMOS LA ORDEN REAL AL NODO 3D
		
	elif comando == "izquierda":
		print("El rover gira a la izquierda")
		mi_rover.izquierda() # <-- ASEGÚRATE QUE LA FUNCIÓN EN EL ROVER SE LLAME ASÍ
		
	elif comando == "derecha":
		print("El rover gira a la derecha")
		mi_rover.derecha()   # <-- ASEGÚRATE QUE LA FUNCIÓN EN EL ROVER SE LLAME ASÍ
		
	else:
		print("Error A.D.A: El rover no conoce el comando '", comando, "'")
