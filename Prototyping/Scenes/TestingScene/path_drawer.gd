extends Node2D

@onready var gamescene = $".."

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	for i in range(1, gamescene.drawn_path.size()):
		var hero_col = gamescene.HeroRules[gamescene.current_hero_path]["color"]
		var pos = gamescene.tilemap_ground.map_to_local(gamescene.drawn_path[i])
		var prev_pos = gamescene.tilemap_ground.map_to_local(gamescene.drawn_path[i - 1])
		draw_line(prev_pos, pos, hero_col, 10.0, false)
