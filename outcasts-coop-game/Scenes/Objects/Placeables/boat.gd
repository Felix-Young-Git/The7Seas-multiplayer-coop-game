class_name Boat
extends CharacterBody2D


const BOAT_SPEED := 300.0

var driver : Player = null
var passengers : Array[Player] = []
var nearby_players: Array[Player] = []

func _on_entry_area_body_entered(body: CharacterBody2D) -> void:
	if body is Player:
		nearby_players.append(body)

func _on_entry_area_body_exited(body: CharacterBody2D) -> void:
	if body is Player:
		nearby_players.erase(body)

func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
	if driver == null:
		return
	var direction = Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)
	velocity = direction * BOAT_SPEED
	move_and_slide()

func interact(player: Player) -> void:
	print("Interact called")
	if player.current_boat == self:
		unboard(player)
	else:
		board(player)

func board(player: Player) -> void:
	if player.current_boat == self:
		return
	passengers.append(player)
	player.current_boat = self
	# First player becomes driver
	if driver == null:
		driver = player
	print(player.name + " boarded")
	player.enter_boat(self)
	


func unboard(player: Player) -> void:
	if !(player.current_boat == self):
		return
	passengers.erase(player)
	player.current_boat = null
	player.global_position = global_position + Vector2(64, 0)
	if driver == player:
		driver = null
		if passengers.size() > 0:
			driver = passengers[0]
	print(player.name + " left")
	player.exit_boat()
