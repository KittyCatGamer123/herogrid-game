extends Node2D

@onready var gamescene = $".."

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for i in range(1, gamescene.drawn_path.size()):
		var pos = gamescene.tilemap_ground.map_to_local(gamescene.drawn_path[i])
		var prev_pos = gamescene.tilemap_ground.map_to_local(gamescene.drawn_path[i - 1])
		draw_line(prev_pos, pos, Color("006fffff"), 10.0, false)
