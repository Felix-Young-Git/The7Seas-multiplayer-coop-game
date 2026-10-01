extends Node2D

#when a player enters the area send signal
func _on_crafting_radius_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_station("workbench")

#when the player exits the area send signal
func _on_crafting_radius_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_station("workbench")
