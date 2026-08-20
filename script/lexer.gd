class_name Lexer
extends RefCounted

# 1. Definimos los tipos de piezas (Tokens) que nuestro lenguaje entiende
enum TipoToken {
	IDENTIFICADOR,   # Palabras como: mi_rover, avanzar, atras, izquierda
	PUNTO,           # El símbolo: .
	PARENTESIS_IZQ,  # El símbolo: (
	PARENTESIS_DER   # El símbolo: )
}

# 2. Función principal que recibe el texto crudo del usuario
func tokenizar(codigo: String) -> Array:
	var tokens: Array = []
	var posicion: int = 0
	var longitud: int = codigo.length()
	
	# Bucle que recorre letra por letra
	while posicion < longitud:
		var caracter = codigo[posicion]
		
		# Ignorar espacios en blanco y saltos de línea
		if caracter == " " or caracter == "\t" or caracter == "\n":
			posicion += 1
			continue
			
		# Detectar el PUNTO
		if caracter == ".":
			tokens.append({"tipo": TipoToken.PUNTO, "valor": "."})
			posicion += 1
			continue
			
		# Detectar Paréntesis
		if caracter == "(":
			tokens.append({"tipo": TipoToken.PARENTESIS_IZQ, "valor": "("})
			posicion += 1
			continue
		if caracter == ")":
			tokens.append({"tipo": TipoToken.PARENTESIS_DER, "valor": ")"})
			posicion += 1
			continue
			
		# Detectar IDENTIFICADORES (nombres de objetos o comandos como "atras")
		if _es_letra(caracter):
			var palabra = ""
			# Seguir leyendo mientras sean letras, números o guiones bajos
			while posicion < longitud and (_es_letra(codigo[posicion]) or _es_numero(codigo[posicion]) or codigo[posicion] == "_"):
				palabra += codigo[posicion]
				posicion += 1
				
			tokens.append({"tipo": TipoToken.IDENTIFICADOR, "valor": palabra})
			continue
			
		# Si el usuario escribe un símbolo raro (ej: @, #), lo saltamos por ahora
		posicion += 1
		
	return tokens

# Funciones de apoyo para saber qué tipo de carácter estamos leyendo
func _es_letra(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")

func _es_numero(c: String) -> bool:
	return c >= "0" and c <= "9"
