extends Control

@onready var panel: PanelContainer = $PanelTransmision
@onready var mensaje: RichTextLabel = $PanelTransmision/Margen/Contenido/Cuerpo/Mensaje
@onready var estado: Label = $PanelTransmision/Margen/Contenido/Cabecera/Estado

var posicion_visible: Vector2
var posicion_oculta: Vector2
var version_mensaje: int = 0
var tween_actual: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	posicion_visible = panel.position
	posicion_oculta = posicion_visible + Vector2(panel.size.x + 40.0, 0.0)
	panel.position = posicion_oculta
	panel.modulate.a = 0.0


func mostrar_mensaje(texto: String, tipo: String = "objetivo", duracion: float = 7.0) -> void:
	version_mensaje += 1
	var mi_version := version_mensaje

	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()

	estado.text = "● TRANSMISION"
	if tipo == "error":
		estado.text = "● ALERTA"
	elif tipo == "progreso":
		estado.text = "● EN CURSO"
	elif tipo == "completado":
		estado.text = "● MISION CUMPLIDA"

	mensaje.text = texto
	mensaje.visible_characters = 0
	panel.show()

	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(panel, "position", posicion_visible, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_actual.tween_property(panel, "modulate:a", 1.0, 0.2)
	await tween_actual.finished

	for cantidad in range(1, texto.length() + 1):
		if mi_version != version_mensaje:
			return
		mensaje.visible_characters = cantidad
		await get_tree().create_timer(0.018).timeout

	await get_tree().create_timer(duracion).timeout
	if mi_version == version_mensaje:
		ocultar()


func ocultar() -> void:
	version_mensaje += 1
	if tween_actual != null and tween_actual.is_valid():
		tween_actual.kill()
	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(panel, "position", posicion_oculta, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_actual.tween_property(panel, "modulate:a", 0.0, 0.22)
	await tween_actual.finished
	panel.hide()
