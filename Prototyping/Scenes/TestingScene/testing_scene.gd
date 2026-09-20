extends Node2D
class_name GameTest

enum HEROS { WARRIOR, LUMBERJACK, ARCHER, MINER }
var HeroRules = {
	HEROS.WARRIOR: { "color": Color("6babff"), "name": "Warrior" },
	HEROS.LUMBERJACK: { "color": Color("ff6b8e"),  "name": "Lumberjack" },
	HEROS.ARCHER: { "color": Color("75ff6b"),  "name": "Archer" },
	HEROS.MINER: { "color": Color("ffba6b"), "name": "Miner" },
}

@onready var gamecamera: Camera2D = $Camera2D

@onready var tilemap_ground: TileMapLayer = $TMGrass
@onready var tilemap_highlight: TileMapLayer = $TMHighlight
var tilemap_highlight_atlas: int
var current_hover_position := Vector2i(-100, -100)

var full_path_queue = []

var drawn_path := []
var drawing_path_active: bool = false
@onready var confirm_path_button: Button = $"../Interface/UI/ConfirmPath"

func _ready() -> void:
	tilemap_highlight_atlas = tilemap_highlight.tile_set.get_source_id(0)

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		gamecamera.position.x += 10
	if Input.is_action_pressed("ui_left"):
		gamecamera.position.x -= 10
	if Input.is_action_pressed("ui_up"):
		gamecamera.position.y -= 10
	if Input.is_action_pressed("ui_down"):
		gamecamera.position.y += 10

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_pos := get_global_mouse_position()
		var cell := tilemap_ground.local_to_map(tilemap_ground.to_local(mouse_pos))
		
		if cell != current_hover_position:
			current_hover_position = cell
			update_hover_position()
		
		if drawing_path_active:
			add_cell_to_path(current_hover_position)
	
	if event is InputEventMouseButton:
		# Awful bad stupid code
		if confirm_path_button.get_global_rect().has_point(event.position):
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing_path_active = event.pressed
			
			if drawing_path_active:
				drawn_path.clear()
				add_cell_to_path(current_hover_position)
				confirm_path_button.visible = false
			else:
				if len(drawn_path) >= 2:
					confirm_path_button.visible = true
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			gamecamera.zoom -= Vector2(0.015, 0.015)
			gamecamera.zoom.x = max(0.45, gamecamera.zoom.x)
			gamecamera.zoom.y = max(0.45, gamecamera.zoom.y)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			gamecamera.zoom += Vector2(0.015, 0.015)
			gamecamera.zoom.x = max(0.45, gamecamera.zoom.x)
			gamecamera.zoom.y = max(0.45, gamecamera.zoom.y)

func update_hover_position() -> void:
	tilemap_highlight.clear()

	if tilemap_ground.get_cell_source_id(current_hover_position) != -1:
		tilemap_highlight.set_cell(current_hover_position, tilemap_highlight_atlas, Vector2i(0, 0))

func add_cell_to_path(cell_position: Vector2i) -> void:
	if tilemap_ground.get_cell_source_id(cell_position) == -1:
		# Not on the tilemap path
		return
	
	if drawn_path.is_empty():
		drawn_path.append(cell_position)
		return
	
	# Undoing while drawing
	var last_cell = drawn_path[-1]
	if cell_position == last_cell: return
	
	if len(drawn_path) >= 2 and cell_position == drawn_path[-2]:
		drawn_path.pop_back()
		queue_redraw()
		return
	
	# Fill in cells skipped during diagonal
	var diff: Vector2i = cell_position - last_cell
	
	if diff.y == 0:
		var step = sign(diff.x)
		for x in range(last_cell.x + step, cell_position.x + step, step):
			drawn_path.append(Vector2i(x, last_cell.y))
	
	if diff.x == 0:
		var step = sign(diff.y)
		for y in range(last_cell.y + step, cell_position.y + step, step):
			drawn_path.append(Vector2i(last_cell.x, y))
	
	queue_redraw()

var queue_item_scene = load("res://Prototyping/Scenes/TestingScene/Queue/Queue.tscn")

func on_confirm_path_pressed() -> void:
	confirm_path_button.visible = false
	full_path_queue.append(drawn_path)
	
	var qi = queue_item_scene.instantiate()
	$"../Interface/UI/QueuePanel/ScrollContainer/Queue".add_child(qi)
	qi.init(self, HEROS.WARRIOR, len(drawn_path))
	
	drawn_path = []
