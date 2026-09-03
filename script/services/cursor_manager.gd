extends Node

const CURSOR_NORMAL: Texture2D = preload("res://assets/cursors/cursor_normal.png")
const CURSOR_HOVER: Texture2D = preload("res://assets/cursors/cursor_hover.png")
const CURSOR_CLICK: Texture2D = preload("res://assets/cursors/cursor_click.png")

const HOTSPOT_NORMAL := Vector2(10, 2)
const HOTSPOT_HOVER := Vector2(2, 2)
const HOTSPOT_CLICK := Vector2(7, 7)

var _click_cursor_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_registrar_cursores()
	get_tree().node_added.connect(_configurar_nodo)
	_configurar_nodos_existentes(get_tree().root)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		if DisplayServer.cursor_get_shape() == Input.CURSOR_POINTING_HAND:
			_click_cursor_active = true
			Input.set_custom_mouse_cursor(
				CURSOR_CLICK,
				Input.CURSOR_POINTING_HAND,
				HOTSPOT_CLICK
			)
	elif _click_cursor_active:
		_click_cursor_active = false
		Input.set_custom_mouse_cursor(
			CURSOR_HOVER,
			Input.CURSOR_POINTING_HAND,
			HOTSPOT_HOVER
		)


func _registrar_cursores() -> void:
	Input.set_custom_mouse_cursor(
		CURSOR_NORMAL,
		Input.CURSOR_ARROW,
		HOTSPOT_NORMAL
	)
	Input.set_custom_mouse_cursor(
		CURSOR_HOVER,
		Input.CURSOR_POINTING_HAND,
		HOTSPOT_HOVER
	)


func _configurar_nodos_existentes(nodo: Node) -> void:
	_configurar_nodo(nodo)
	for hijo in nodo.get_children():
		_configurar_nodos_existentes(hijo)


func _configurar_nodo(nodo: Node) -> void:
	if nodo is BaseButton:
		nodo.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
