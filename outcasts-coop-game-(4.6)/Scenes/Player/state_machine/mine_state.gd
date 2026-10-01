extends NodeState

@export var player: Player
@export var animated_sprite_2d: AnimatedSprite2D
@export var hit_component_collision_shape: CollisionShape2D
@export var hit_component: HitComponent

func _ready() -> void:
	hit_component_collision_shape.disabled = true
	hit_component_collision_shape.position = Vector2(0, 0)

func _on_process(_delta : float) -> void:
	pass


func _on_physics_process(_delta : float) -> void:
	pass


func _on_next_transitions() -> void:
	#If the chopping animation isn't playing, go back to idle
	if !animated_sprite_2d.is_playing():
		transition.emit("Idle")


func _on_enter() -> void:
	#Check which direction the player is facing to choose the animation and reposition the 
	#hit box of the hit component to line up with the animation
	if player.player_direction == Vector2.UP:
		animated_sprite_2d.play("Mining Back")
		hit_component_collision_shape.position = Vector2(0, -18)
	elif player.player_direction == Vector2.DOWN:
		animated_sprite_2d.play("Mining Front")
		hit_component_collision_shape.position = Vector2(0, 3)
	elif player.player_direction == Vector2.LEFT:
		animated_sprite_2d.play("Mining Left")
		hit_component_collision_shape.position = Vector2(-9, 0)
	elif player.player_direction == Vector2.RIGHT:
		animated_sprite_2d.play("Mining Right")
		hit_component_collision_shape.position = Vector2(9, 0)
	else:
		animated_sprite_2d.play("Mining Front")
		
	hit_component_collision_shape.disabled = false
	hit_component.current_tool = DataTypes.Tools.Pickaxe


func _on_exit() -> void:
	animated_sprite_2d.stop()
	hit_component_collision_shape.disabled = true
