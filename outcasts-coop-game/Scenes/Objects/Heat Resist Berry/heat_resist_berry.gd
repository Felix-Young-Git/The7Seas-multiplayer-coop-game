extends Area2D

@onready var sprite : Sprite2D = $Sprite2D
@export var sprite_picked : Texture

var nearby_players: Array[Player] = []

var has_berries : bool = true
signal bush_picked(cell: Vector2i)

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)

#if clicked and player nearby, harvest
func _on_input_event(viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if has_berries == false:
			return
		if nearby_players.is_empty():
			return
		var player = nearby_players[0]
		harvest()

#send signal and update sprite
func harvest():
	var tilemap = get_parent()
	var cell = tilemap.local_to_map(tilemap.to_local(global_position))
	bush_picked.emit(cell)
	
func update_bush_to_picked():
	sprite.texture = sprite_picked

func get_cell_from_self() -> Vector2i:
	var tilemap = get_parent()
	return tilemap.local_to_map(
		tilemap.to_local(global_position)
	)


func _on_pick_area_body_entered(body: Node2D) -> void:
	if body is Player:
		nearby_players.append(body)
		


func _on_pick_area_body_exited(body: Node2D) -> void:
	if body is Player:
		nearby_players.erase(body)
