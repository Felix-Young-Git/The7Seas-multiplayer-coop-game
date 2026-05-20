extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D


func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	if is_multiplayer_authority():
		if player.player_direction == Vector2.UP:
			animated_sprite_2d.play("Idle Back")
		elif player.player_direction == Vector2.DOWN:
			animated_sprite_2d.play("Idle Front")
		elif player.player_direction == Vector2.LEFT:
			animated_sprite_2d.play("Idle Left")
		elif player.player_direction == Vector2.RIGHT:
			animated_sprite_2d.play("Idle Right")
		else:
			animated_sprite_2d.play("Idle Front")



func _on_next_transitions() -> void:
	if is_multiplayer_authority():
		GameInputEvents.movement_input()
		
		if GameInputEvents.is_movement_input():
			transition.emit("Walk")
	
		#TOOLS
		if player.current_tool == DataTypes.Tools.Axe && GameInputEvents.use_tool():
			transition.emit("Chop")
		
		#if player.current_tool == DataTypes.Tools.TillGround && GameInputEvents.use_tool():
		#	transition.emit("Tilling")
	
		#if player.current_tool == DataTypes.Tools.WaterCrops && GameInputEvents.use_tool():
		#	transition.emit("Watering")


func _on_enter() -> void:
	pass


func _on_exit() -> void:
	if is_multiplayer_authority():
		animated_sprite_2d.stop()
