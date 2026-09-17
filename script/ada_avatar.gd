extends Control

var tiempo: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	var centro := size * 0.5
	var pulso: float = sin(tiempo * 2.4) * 0.5 + 0.5
	var verde_brillante := Color(0.7608024, 0.9369633, 0.7753063, 0.95)
	var verde_borde := Color(0.3744904, 0.5937168, 0.41924155, 0.85)
	var verde_suave := Color(0.3744904, 0.5937168, 0.41924155, 0.22)
	var verde_texto := Color(0.8651328, 0.9999998, 0.866359, 0.95)

	# Avatar
	draw_circle(centro, 35.0 + pulso * 3.0, verde_suave)
	draw_arc(centro, 42.0, tiempo, tiempo + 4.5, 42, verde_borde, 2.0, false)
	draw_arc(centro, 51.0, -tiempo * 0.7, -tiempo * 0.7 + 3.4, 42, Color(0.3744904, 0.5937168, 0.41924155, 0.55), 2.0, false)
	draw_circle(centro, 12.0 + pulso * 2.0, verde_texto)
	draw_circle(centro, 5.0, Color.WHITE)

	for indice in range(8):
		var angulo: float = TAU * float(indice) / 8.0 + tiempo * 0.15
		var inicio := centro + Vector2.from_angle(angulo) * 57.0
		var final := centro + Vector2.from_angle(angulo) * 65.0
		draw_line(inicio, final, verde_brillante, 2.0, false)

	var base_y: float = size.y - 22.0
	for indice in range(11):
		var altura: float = 4.0 + abs(sin(tiempo * 5.0 + indice * 0.8)) * 13.0
		var x: float = centro.x - 40.0 + indice * 8.0
		draw_line(Vector2(x, base_y - altura), Vector2(x, base_y + altura), verde_brillante, 2.0, false)
