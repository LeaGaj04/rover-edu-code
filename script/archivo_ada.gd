extends Control

signal cerrado

# --- DICCIONARIO DE CONOCIMIENTO (GDD Sección 7.2) ---
const CONOCIMIENTOS := {
	"objeto": {
		"nombre": "Objeto",
		"categoria": "Fundamentos",
		"descripcion": "En programación orientada a objetos (POO), un objeto es una entidad que combina propiedades y acciones. En EduCode, tu Rover es el objeto principal que controlas mediante código.",
		"sintaxis": "rover.<metodo>()",
		"ejemplo": "rover.minar()\n# 'rover' es el objeto que ejecuta la instrucción.",
		"errores": "Escribir mal el nombre del objeto o usar mayúsculas (ej: Rover.minar() o rver.minar())."
	},
	"metodo": {
		"nombre": "Método",
		"categoria": "Fundamentos",
		"descripcion": "Un método es una acción o comando que un objeto sabe realizar. Siempre va acompañado de paréntesis '()', que pueden o no llevar datos en su interior.",
		"sintaxis": "objeto.nombre_metodo()",
		"ejemplo": "rover.minar()\nrover.transferir()\nrover.norte()",
		"errores": "Olvidar los paréntesis obligatorios (ej: escribir 'rover.minar' sin '()') o usar comas en vez de puntos."
	},
	"secuencia": {
		"nombre": "Secuencia de Código",
		"categoria": "Fundamentos",
		"descripcion": "El ordenador ejecuta las instrucciones en orden secuencial: de arriba hacia abajo y una por una. El orden lógico de tus líneas determina si el rover cumple o falla la misión.",
		"sintaxis": "instruccion_1\ninstruccion_2\ninstruccion_3",
		"ejemplo": "rover.norte()\nrover.minar()\nrover.sur()\nrover.transferir()",
		"errores": "Intentar transferir antes de minar o antes de regresar a la casilla de la nave."
	},
	"parametro": {
		"nombre": "Parámetros (Argumentos)",
		"categoria": "Fundamentos",
		"descripcion": "Los parámetros son valores numéricos que enviamos dentro de los paréntesis de un método para modificar su comportamiento, como indicar la cantidad exacta de pasos a avanzar.",
		"sintaxis": "rover.direccion(cantidad)",
		"ejemplo": "rover.norte(2)  # Avanza dos casillas al norte\nrover.sur(3)    # Avanza tres casillas al sur",
		"errores": "Enviar números negativos, texto o enviar parámetros a comandos que no los reciben (como rover.minar(5))."
	},
	"bucle_for": {
		"nombre": "Bucle For (Repetición)",
		"categoria": "Control",
		"descripcion": "Estructura de control que permite repetir un bloque de instrucciones un número exacto de veces usando range(N). Todo lo que se repite debe llevar sangría (tabulación o 4 espacios).",
		"sintaxis": "for <variable> in range(<repeticiones>):\n    <instrucciones_con_sangria>",
		"ejemplo": "for ciclo in range(10):\n    rover.norte()\n    rover.minar()\n    rover.sur()\nrover.transferir()  # Fuera del bucle",
		"errores": "Olvidar los dos puntos ':' al final de range(), o no aplicar sangría a las instrucciones interiores."
	},
	"condicional_if": {
		"nombre": "Condicional If",
		"categoria": "Control",
		"descripcion": "Permite al rover tomar decisiones lógicas en base al estado de sus sensores o del terreno. Si la condición es verdadera, ejecuta el bloque.",
		"sintaxis": "if <condicion>:\n    <instrucciones>",
		"ejemplo": "# Próximamente en misiones con sensores",
		"errores": "Archivo cifrado. Requiere completar misiones de exploración avanzada."
	},
	"bucle_while": {
		"nombre": "Bucle While",
		"categoria": "Control",
		"descripcion": "Repite un bloque de código continuamente mientras una condición siga siendo verdadera. Requiere una condición de salida para no crear bucles infinitos.",
		"sintaxis": "while <condicion>:\n    <instrucciones>",
		"ejemplo": "# Próximamente en misiones de automatización avanzada",
		"errores": "Archivo cifrado. Requiere completar misiones de exploración avanzada."
	},
	"variable": {
		"nombre": "Variables",
		"categoria": "Organización",
		"descripcion": "Espacios de memoria con nombre para almacenar datos dinámicos (como números o textos) y utilizarlos más adelante.",
		"sintaxis": "nombre_variable = valor",
		"ejemplo": "# Próximamente",
		"errores": "Archivo cifrado."
	},
	"funcion": {
		"nombre": "Funciones Propias",
		"categoria": "Organización",
		"descripcion": "Bloques de código personalizados definidos por el jugador para reutilizar rutinas complejas sin duplicar código.",
		"sintaxis": "def mi_rutina():\n    <instrucciones>",
		"ejemplo": "# Próximamente",
		"errores": "Archivo cifrado."
	}
}

var categoria_actual: String = "Fundamentos"
var concepto_actual_id: String = "objeto"

@onready var contenedor_lista: VBoxContainer = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaIzquierda/Scroll/ListaConceptos
@onready var label_titulo: Label = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/TituloConcepto
@onready var label_estado: Label = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/EstadoConcepto
@onready var txt_descripcion: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Descripcion
@onready var txt_sintaxis: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Sintaxis
@onready var txt_ejemplo: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Ejemplo
@onready var txt_errores: RichTextLabel = $Centro/PanelPrincipal/VBox/Cuerpo/ColumnaDerecha/Scroll/Detalle/Errores

@onready var btn_fundamentos: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonFundamentos
@onready var btn_control: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonControl
@onready var btn_organizacion: Button = $Centro/PanelPrincipal/VBox/Pestanas/BotonOrganizacion


func _ready() -> void:
	hide()
	btn_fundamentos.pressed.connect(_cambiar_categoria.bind("Fundamentos"))
	btn_control.pressed.connect(_cambiar_categoria.bind("Control"))
	btn_organizacion.pressed.connect(_cambiar_categoria.bind("Organización"))
	$Centro/PanelPrincipal/VBox/Cabecera/BotonCerrar.pressed.connect(cerrar)


func abrir() -> void:
	show()
	_cambiar_categoria("Fundamentos")


func cerrar() -> void:
	hide()
	cerrado.emit()


func _cambiar_categoria(categoria: String) -> void:
	categoria_actual = categoria

	# Resaltar pestaña activa
	btn_fundamentos.modulate = Color(1.2, 1.2, 1.2) if categoria == "Fundamentos" else Color(0.7, 0.7, 0.7)
	btn_control.modulate = Color(1.2, 1.2, 1.2) if categoria == "Control" else Color(0.7, 0.7, 0.7)
	btn_organizacion.modulate = Color(1.2, 1.2, 1.2) if categoria == "Organización" else Color(0.7, 0.7, 0.7)

	_poblar_lista_conceptos()


func _poblar_lista_conceptos() -> void:
	for hijo in contenedor_lista.get_children():
		hijo.queue_free()

	var conocimientos_desbloqueados: Array = MissionService.get_unlocked_knowledge()
	var primer_concepto := ""

	for id_clave in CONOCIMIENTOS:
		var datos = CONOCIMIENTOS[id_clave]
		if datos["categoria"] != categoria_actual:
			continue

		var esta_desbloqueado = id_clave in conocimientos_desbloqueados
		var boton := Button.new()
		boton.text = datos["nombre"] if esta_desbloqueado else "[ CIFRADO ] " + datos["nombre"]
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.custom_minimum_size = Vector2(0, 44)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if esta_desbloqueado:
			boton.modulate = Color(0.76, 0.94, 0.78)
		else:
			boton.modulate = Color(0.5, 0.5, 0.55)

		boton.pressed.connect(_seleccionar_concepto.bind(id_clave))
		contenedor_lista.add_child(boton)

		if primer_concepto.is_empty():
			primer_concepto = id_clave

	if not primer_concepto.is_empty():
		_seleccionar_concepto(primer_concepto)


func _seleccionar_concepto(id_clave: String) -> void:
	concepto_actual_id = id_clave
	var datos = CONOCIMIENTOS.get(id_clave, {})
	var esta_desbloqueado = id_clave in MissionService.get_unlocked_knowledge()

	if esta_desbloqueado:
		label_titulo.text = "◆ " + datos.get("nombre", "").to_upper()
		label_estado.text = "● ESTADO: DESBLOQUEADO"
		label_estado.modulate = Color(0.25, 1.0, 0.88)
		txt_descripcion.text = datos.get("descripcion", "")
		txt_sintaxis.text = "[code]" + datos.get("sintaxis", "") + "[/code]"
		txt_ejemplo.text = "[code]" + datos.get("ejemplo", "") + "[/code]"
		txt_errores.text = datos.get("errores", "")
	else:
		label_titulo.text = "◆ " + datos.get("nombre", "").to_upper() + " [ENCRIPTADO]"
		label_estado.text = "● ESTADO: ARCHIVO CIFRADO"
		label_estado.modulate = Color(0.9, 0.4, 0.4)
		txt_descripcion.text = "Este banco de datos se encuentra cifrado. Para descifrarlo debes desbloquear y superar misiones de exploración avanzadas en el asteroide."
		txt_sintaxis.text = "[code]??? [/code]"
		txt_ejemplo.text = "[code]# ACCESO DENEGADO POR SEGURIDAD DE A.D.A.[/code]"
		txt_errores.text = "Información clasificada hasta nueva asignación de misión."
