extends Node2D
class_name GameTest

enum HEROS { WARRIOR, LUMBERJACK, ARCHER, MINER }
@onready var HeroRules = {
	HEROS.WARRIOR: { "color": Color("6babff"), "name": "Warrior", "ref": $Warrior },
	HEROS.LUMBERJACK: { "color": Color("ff6b8e"), "name": "Lumberjack", "ref": $Lumberjack },
	HEROS.ARCHER: { "color": Color("75ff6b"), "name": "Archer" },
	HEROS.MINER: { "color": Color("ffba6b"), "name": "Miner" },
}

@onready var gamecamera: Camera2D = $Camera2D

@onready var tilemap_ground: TileMapLayer = $TMGrass
@onready var tilemap_trees: TileMapLayer = $TMTrees
@onready var tilemap_highlight: TileMapLayer = $TMHighlight
var tilemap_highlight_atlas: int
var current_hover_position := Vector2i(-100, -100)

var full_path_queue = []
var full_path_queue_chars = []
var run_mode_active: bool = false
@onready var char_warrior = $Warrior

var drawn_path := []
var drawing_path_active: bool = false
var current_hero_path: HEROS = HEROS.WARRIOR
@onready var confirm_path_button: Button = $"../Interface/UI/ConfirmPath"
@onready var start_path_button: Button = $"../Interface/UI/Start"
@onready var retry_path_button: Button = $"../Interface/UI/ResetPath"

func _ready() -> void:
	tilemap_highlight_atlas = tilemap_highlight.tile_set.get_source_id(0)
	$"../Interface/UI/HeroMode".color = HeroRules[current_hero_path]["color"]

func _process(_delta: float) -> void:
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
		
		if drawing_path_active and (not run_mode_active):
			add_cell_to_path(current_hover_position)
	
	if event is InputEventMouseButton:
		# Awful bad stupid code
		if control_node_clicked(confirm_path_button, event) or control_node_clicked(retry_path_button, event):
			return
		if control_node_clicked(start_path_button, event):
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing_path_active = event.pressed
			
			if drawing_path_active and (not run_mode_active):
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
	
	if event is InputEventKey:
		if event.is_action_released("char_1"):
			print("Character Lane 1")
			drawn_path = []
			current_hero_path = HEROS.WARRIOR
		elif event.is_action_released("char_2"):
			print("Character Lane 2")
			drawn_path = []
			current_hero_path = HEROS.LUMBERJACK
		$"../Interface/UI/HeroMode".color = HeroRules[current_hero_path]["color"]

func update_hover_position() -> void:
	tilemap_highlight.clear()

	if tilemap_ground.get_cell_source_id(current_hover_position) != -1:
		tilemap_highlight.set_cell(current_hover_position, tilemap_highlight_atlas, Vector2i(0, 0))

func add_cell_to_path(cell_position: Vector2i) -> void:
	if not hero_can_enter(cell_position):
		return
	
	if drawn_path.is_empty():
		drawn_path.append(cell_position)
		queue_redraw()
		return
	
	var last_cell: Vector2i = drawn_path[-1]

	if cell_position == last_cell:
		return
	
	# Undoing while drawing backwards
	if len(drawn_path) >= 2 and cell_position == drawn_path[-2]:
		drawn_path.pop_back()
		queue_redraw()
		return
	
	var diff := cell_position - last_cell
	
	# Only support horizontal/vertical movement
	if diff.x != 0 and diff.y != 0:
		return
	
	var step: Vector2i
	
	if diff.x != 0:
		step = Vector2i(sign(diff.x), 0)
	else:
		step = Vector2i(0, sign(diff.y))
	
	var cells_to_add: Array[Vector2i] = []
	var check_cell := last_cell + step
	
	while check_cell != cell_position + step:
		if not hero_can_enter(check_cell):
			return
		
		cells_to_add.append(check_cell)
		check_cell += step
	
	drawn_path.append_array(cells_to_add)
	queue_redraw()

func is_specified_tilemap(tm: TileMapLayer, cell: Vector2i) -> bool:
	return tm.get_cell_source_id(cell) != -1

func is_walkable_tile(cell: Vector2i) -> bool:
	return is_specified_tilemap(tilemap_ground, cell)

func hero_can_enter(cell: Vector2i) -> bool:
	if is_specified_tilemap(tilemap_ground, cell):
		return true
	
	if is_specified_tilemap(tilemap_trees, cell):
		return (current_hero_path == HEROS.LUMBERJACK)
	
	return false

var queue_item_scene = load("res://Prototyping/Scenes/TestingScene/Queue/Queue.tscn")

func on_confirm_path_pressed() -> void:
	confirm_path_button.visible = false
	full_path_queue.append(drawn_path)
	full_path_queue_chars.append(current_hero_path)
	
	var qi = queue_item_scene.instantiate()
	$"../Interface/UI/QueuePanel/ScrollContainer/Queue".add_child(qi)
	qi.path = drawn_path
	qi.init(self, current_hero_path, len(drawn_path))
	
	drawn_path = []

func control_node_clicked(node, event) -> bool:
	return node.get_global_rect().has_point(event.position)

func start_pressed() -> void:
	if len(full_path_queue) < 1:
		return
	
	run_mode_active = true
	start_path_button.disabled = true
	drawn_path = []
	confirm_path_button.visible = false
	run_simulation()

func reset_path_pressed() -> void:
	get_tree().reload_current_scene()

func run_simulation() -> void:
	await get_tree().create_timer(0.1).timeout
	
	for idx in range(0, len(full_path_queue)):
		var path = full_path_queue[idx]
		var hero = full_path_queue_chars[idx]
		var heroref = HeroRules[hero]["ref"]
		
		for next_position in path: 
			var tween = create_tween()
			var pos = tilemap_ground.map_to_local(next_position)
			await tween.tween_property(heroref, "position", pos, 0.1).finished
			
			if is_specified_tilemap(tilemap_trees, next_position):
				if hero == HEROS.LUMBERJACK:
					await destroy_obstacle(tilemap_trees, next_position)
			
			await get_tree().create_timer(0.2).timeout
		await get_tree().create_timer(0.65).timeout
	
	await get_tree().create_timer(0.4).timeout
	retry_path_button.visible = true

func destroy_obstacle(obstacle_tm: TileMapLayer, cell: Vector2i) -> void:
	await get_tree().create_timer(2).timeout
	obstacle_tm.erase_cell(cell)
	tilemap_ground.set_cell(cell, 1, Vector2i(0,0))
	return
