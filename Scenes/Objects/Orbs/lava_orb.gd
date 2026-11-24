extends Node2D


#when the player enters the area, emit a signal to tell the tilemap to 
#remove this tile and to update the sprites on the lava pedestal.

signal lavaOrbCollected

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if body is Player:
		lavaOrbCollected.emit(get_cell_from_self())


func get_cell_from_self() -> Vector2i:
	var tilemap = get_parent()
	return tilemap.local_to_map(
		tilemap.to_local(global_position)
	)
