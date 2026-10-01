extends Node2D

var boats_in_range: Array[Boat] = []
var player_in_range: bool = false

#recolor the existing sprite so its different from the reg workbench
func _enter_tree() -> void:
	self_modulate = Color(0.4, 0.7, 1.0) # tints toward blue


#when a player enters the area send signal
func _on_crafting_radius_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_station("boat_workbench")

#when the player exits the area send signal
func _on_crafting_radius_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_station("boat_workbench")

#crafting
func get_nearby_boat() -> Boat:
	if boats_in_range.is_empty():
		return null
	if boats_in_range.size() == 1:
		return boats_in_range[0]
	# multiple boats in range — pick nearest to the workbench
	boats_in_range.sort_custom(func(a, b):
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	return boats_in_range[0]

func craft_upgrade(module: BoatModule) -> bool:
	var target_boat = get_nearby_boat()
	if target_boat == null:
		return false  # no boat to install onto
	target_boat.install_upgrade(module)
	return true


#update if boats in area
func _on_boat_upgrade_radius_body_entered(body: Node2D) -> void:
	if body is Boat:
		boats_in_range.append(body)

func _on_boat_upgrade_radius_body_exited(body: Node2D) -> void:
	if body is Boat:
		boats_in_range.erase(body)
