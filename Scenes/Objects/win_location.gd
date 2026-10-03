extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
		
	if body is Player:
		show_end_screen.rpc()


@rpc("authority", "call_local", "reliable")
func show_end_screen():
	get_tree().change_scene_to_file("res://Scenes/screens/end_screen.tscn")
