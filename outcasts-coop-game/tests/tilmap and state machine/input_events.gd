class_name GameInputEvents

static var direction: Vector2

#get direction
static func movement_input() -> Vector2:
	if Input.is_action_pressed("Left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("Right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("Down"):
		direction = Vector2.DOWN
	elif Input.is_action_pressed("Up"):
		direction = Vector2.UP
	else:
		direction = Vector2.ZERO
		
	return direction



#chech if getting movement input
static func is_movement_input() -> bool:
	if direction == Vector2.ZERO:
		return false
	else:
		return true

#checks if the user clicks the left mouse button
#static func use_tool() -> bool:
#	var use_tool_value: bool = Input.is_action_just_pressed("Hit")
#	return use_tool_value
