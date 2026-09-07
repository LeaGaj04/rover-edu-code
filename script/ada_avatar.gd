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
	var cyan := Color(0.25, 1.0, 0.88, 0.9)
	var cyan_suave := Color(0.25, 1.0, 0.88, 0.18)

	# Anillos del nucleo de A.D.A.
	draw_circle(centro, 35.0 + pulso * 3.0, cyan_suave)
	draw_arc(centro, 42.0, tiempo, tiempo + 4.5, 42, cyan, 2.0, false)
	draw_arc(centro, 51.0, -tiempo * 0.7, -tiempo * 0.7 + 3.4, 42, Color(0.45, 0.62, 1.0, 0.65), 2.0, false)
	draw_circle(centro, 12.0 + pulso * 2.0, Color(0.7, 1.0, 0.94, 0.9))
	draw_circle(centro, 5.0, Color.WHITE)

	# Marcas tecnicas alrededor del nucleo.
	for indice in range(8):
		var angulo: float = TAU * float(indice) / 8.0 + tiempo * 0.15
		var inicio := centro + Vector2.from_angle(angulo) * 57.0
		var final := centro + Vector2.from_angle(angulo) * 65.0
		draw_line(inicio, final, cyan, 2.0, false)

	# Onda de voz en la parte inferior.
	var base_y: float = size.y - 22.0
	for indice in range(11):
		var altura: float = 4.0 + abs(sin(tiempo * 5.0 + indice * 0.8)) * 13.0
		var x: float = centro.x - 40.0 + indice * 8.0
		draw_line(Vector2(x, base_y - altura), Vector2(x, base_y + altura), cyan, 2.0, false)
