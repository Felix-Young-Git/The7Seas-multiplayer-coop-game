extends CanvasLayer

func _ready():
	$"BoxContainer/Replay Button".pressed.connect(_on_back_to_menu_pressed)
	$"BoxContainer/Quit Button".pressed.connect(_on_quit_button_pressed)
	multiplayer.server_disconnected.connect(_on_back_to_menu_pressed)

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_back_to_menu_pressed():
	print("pressed")
	await EosNetwork.exit_game()
	print("done waiting")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/screens/inventory_test.tscn")
