extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		show_end_screen.rpc()


@rpc("any_peer", "call_local", "reliable")
func show_end_screen():
	get_tree().change_scene_to_file("res://Scenes/screens/end_screen.tscn")
