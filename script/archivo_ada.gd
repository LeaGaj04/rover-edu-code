extends Control

signal cerrado

# Códice
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
	"bucle_while": {
		"nombre": "Bucle While (Automatización)",
		"categoria": "Control",
		"descripcion": "Estructura de control que repite un bloque de instrucciones continuamente mientras una condición sea verdadera. Permite automatizar rutinas continuas de suministro y patrullaje.",
		"sintaxis": "while <condicion>:\n    <instrucciones_con_sangria>",
		"ejemplo": "# Ciclo continuo de suministro:\nwhile True:\n    rover.norte()\n    rover.minar()\n    rover.sur()\n    rover.transferir()\n\n# O según el espacio en bodega:\nwhile rover.tiene_espacio():\n    rover.minar()",
		"errores": "Olvidar los dos puntos ':' al final, olvidar aplicar sangría a las acciones interiores, o no incluir una condición de parada o retorno a base."
	},
	"bucle_for": {
		"nombre": "Bucle For (Repetición Exacta)",
		"categoria": "Control",
		"descripcion": "Estructura de control que permite repetir un bloque de instrucciones un número exacto de veces usando range(N). Todo lo que se repite debe llevar sangría (tabulación o 4 espacios).",
		"sintaxis": "for <variable> in range(<repeticiones>):\n    <instrucciones_con_sangria>",
		"ejemplo": "for ciclo in range(10):\n    rover.norte()\n    rover.minar()\n    rover.sur()\nrover.transferir()  # Fuera del bucle",
		"errores": "Olvidar los dos puntos ':' al final de range(), o no aplicar sangría a las instrucciones interiores."
	},
	"condicional_if": {
		"nombre": "Condicional If (Decisiones)",
		"categoria": "Control",
		"descripcion": "Permite al rover tomar decisiones lógicas en base al estado de sus sensores o del terreno. Si la condición es verdadera, ejecuta el bloque.",
		"sintaxis": "if <condicion>:\n    <instrucciones_con_sangria>",
		"ejemplo": "if rover.hay_mineral():\n    rover.minar()",
		"errores": "Olvidar los dos puntos ':', olvidar los paréntesis en los sensores (ej: 'rover.hay_mineral' sin '()') o no aplicar sangría a la acción interior."
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


var estilo_concepto_normal: StyleBoxFlat
var estilo_concepto_hover: StyleBoxFlat
var estilo_concepto_selected: StyleBoxFlat
var estilo_concepto_cifrado: StyleBoxFlat
var botones_por_id: Dictionary = {}


func _ready() -> void:
	hide()
	_inicializar_estilos_conceptos()
	btn_fundamentos.pressed.connect(_cambiar_categoria.bind("Fundamentos"))
	btn_control.pressed.connect(_cambiar_categoria.bind("Control"))
	btn_organizacion.pressed.connect(_cambiar_categoria.bind("Organización"))
	$Centro/PanelPrincipal/VBox/Cabecera/BotonCerrar.pressed.connect(cerrar)


func _inicializar_estilos_conceptos() -> void:
	estilo_concepto_normal = StyleBoxFlat.new()
	estilo_concepto_normal.bg_color = Color(0.0, 0.06666667, 0.0, 0.76)
	estilo_concepto_normal.border_color = Color(0.37254903, 0.5921569, 0.41960785, 0.85)
	estilo_concepto_normal.set_border_width_all(2)
	estilo_concepto_normal.set_corner_radius_all(10)
	estilo_concepto_normal.content_margin_left = 14.0
	estilo_concepto_normal.content_margin_top = 8.0
	estilo_concepto_normal.content_margin_right = 14.0
	estilo_concepto_normal.content_margin_bottom = 8.0
	estilo_concepto_normal.shadow_color = Color(0.0039, 0.09, 0.011, 0.65)
	estilo_concepto_normal.shadow_offset = Vector2(3, 3)

	estilo_concepto_hover = StyleBoxFlat.new()
	estilo_concepto_hover.bg_color = Color(0.015, 0.12, 0.025, 0.92)
	estilo_concepto_hover.border_color = Color(0.48, 0.76, 0.54, 1.0)
	estilo_concepto_hover.set_border_width_all(2)
	estilo_concepto_hover.set_corner_radius_all(10)
	estilo_concepto_hover.content_margin_left = 14.0
	estilo_concepto_hover.content_margin_top = 8.0
	estilo_concepto_hover.content_margin_right = 14.0
	estilo_concepto_hover.content_margin_bottom = 8.0
	estilo_concepto_hover.expand_margin_left = 1.0
	estilo_concepto_hover.expand_margin_top = 1.0
	estilo_concepto_hover.expand_margin_right = 1.0
	estilo_concepto_hover.expand_margin_bottom = 1.0
	estilo_concepto_hover.shadow_color = Color(0.0039, 0.09, 0.011, 0.65)
	estilo_concepto_hover.shadow_offset = Vector2(3, 3)

	estilo_concepto_selected = StyleBoxFlat.new()
	estilo_concepto_selected.bg_color = Color(0.025, 0.14, 0.04, 0.95)
	estilo_concepto_selected.border_color = Color(0.7607843, 0.9372549, 0.7764706, 1.0)
	estilo_concepto_selected.set_border_width_all(2)
	estilo_concepto_selected.set_corner_radius_all(10)
	estilo_concepto_selected.content_margin_left = 14.0
	estilo_concepto_selected.content_margin_top = 8.0
	estilo_concepto_selected.content_margin_right = 14.0
	estilo_concepto_selected.content_margin_bottom = 8.0
	estilo_concepto_selected.shadow_color = Color(0.0039, 0.09, 0.011, 0.75)
	estilo_concepto_selected.shadow_offset = Vector2(4, 4)

	estilo_concepto_cifrado = StyleBoxFlat.new()
	estilo_concepto_cifrado.bg_color = Color(0.01, 0.03, 0.015, 0.6)
	estilo_concepto_cifrado.border_color = Color(0.25, 0.4, 0.3, 0.45)
	estilo_concepto_cifrado.set_border_width_all(1)
	estilo_concepto_cifrado.set_corner_radius_all(10)
	estilo_concepto_cifrado.content_margin_left = 14.0
	estilo_concepto_cifrado.content_margin_top = 8.0
	estilo_concepto_cifrado.content_margin_right = 14.0
	estilo_concepto_cifrado.content_margin_bottom = 8.0


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
	botones_por_id.clear()
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
		boton.custom_minimum_size = Vector2(0, 42)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		boton.add_theme_font_size_override("font_size", 14)
		boton.add_theme_color_override("font_outline_color", Color(0.025, 0.02, 0.055, 1))
		boton.add_theme_constant_override("outline_size", 2)

		if esta_desbloqueado:
			boton.add_theme_color_override("font_color", Color(0.7607843, 0.9372549, 0.7764706, 1))
			boton.add_theme_color_override("font_hover_color", Color(0.92, 1.0, 0.92, 1))
			boton.add_theme_stylebox_override("normal", estilo_concepto_normal)
			boton.add_theme_stylebox_override("hover", estilo_concepto_hover)
			boton.add_theme_stylebox_override("focus", estilo_concepto_selected)
		else:
			boton.add_theme_color_override("font_color", Color(0.45, 0.6, 0.5, 0.75))
			boton.add_theme_color_override("font_hover_color", Color(0.6, 0.75, 0.65, 0.9))
			boton.add_theme_stylebox_override("normal", estilo_concepto_cifrado)
			boton.add_theme_stylebox_override("hover", estilo_concepto_hover)
			boton.add_theme_stylebox_override("focus", estilo_concepto_cifrado)

		botones_por_id[id_clave] = boton
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

	# Resaltar el botón activo en la lista
	for clave in botones_por_id:
		var btn: Button = botones_por_id[clave]
		if is_instance_valid(btn):
			var desbloq = clave in MissionService.get_unlocked_knowledge()
			if clave == id_clave:
				btn.add_theme_stylebox_override("normal", estilo_concepto_selected)
			else:
				btn.add_theme_stylebox_override("normal", estilo_concepto_normal if desbloq else estilo_concepto_cifrado)

	if esta_desbloqueado:
		label_titulo.text = "◆ " + datos.get("nombre", "").to_upper()
		label_estado.text = "● ESTADO: DESBLOQUEADO"
		label_estado.modulate = Color(0.7608024, 0.9369633, 0.7753063)
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
