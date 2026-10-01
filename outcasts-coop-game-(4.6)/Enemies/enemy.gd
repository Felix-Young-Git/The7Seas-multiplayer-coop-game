extends CharacterBody2D

var SPEED : float = 20

#set server as the one that controls enemies
func _ready() -> void:
	if multiplayer.is_server():
		set_multiplayer_authority(1)

#get closest player
func get_closest_player():
	var players = get_tree().get_nodes_in_group("players")
	var closest = null
	var closest_dist = INF

	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = p

	return closest

#move toward closest player
func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	var target = get_closest_player()
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
