class_name Boat
extends CharacterBody2D

const BOAT_SPEED := 300.0

var driver_peer_id : int = -1
var passengers : Array[Player] = []
var nearby_players: Array[Player] = []

func _ready() -> void:
	print("Boat authority: ", get_multiplayer_authority(), " local peer: ", multiplayer.get_unique_id())

#area interaction
func _on_entry_area_body_entered(body: CharacterBody2D) -> void:
	if body is Player:
		nearby_players.append(body)

func _on_entry_area_body_exited(body: CharacterBody2D) -> void:
	if body is Player:
		nearby_players.erase(body)

#movement
func _physics_process(_delta: float) -> void:
	if !is_multiplayer_authority():
		return
	
	if driver_peer_id == -1:
		return

	if multiplayer.get_unique_id() != driver_peer_id:
		return
	
	var direction = Input.get_vector(
		"Left",
		"Right",
		"Up",
		"Down"
	)
	
	
	velocity = direction * BOAT_SPEED
	move_and_slide()


#interacting with boat
func interact(player: Player) -> void:
	if player.current_boat == self:
		unboard(player)
	else:
		board(player)

func board(player: Player) -> void:
	if !multiplayer.is_server():
		return
	if player.current_boat == self:
		return
	passengers.append(player)
	player.current_boat = self
	# First player becomes driver
	if driver_peer_id == -1:
		driver_peer_id = player.get_multiplayer_authority()
		
	set_multiplayer_authority(driver_peer_id)
		#sync_authority.rpc(peer_id)
	sync_driver.rpc(driver_peer_id)
	print(player.name + " boarded")
	player.enter_boat.rpc(get_path())


func unboard(player: Player) -> void:
	if !multiplayer.is_server():
		return
	if !(player.current_boat == self):
		return
	passengers.erase(player)
	player.current_boat = null
	player.global_position = global_position + Vector2(64, 0)
	if driver_peer_id == player.get_multiplayer_authority():
		if passengers.size() > 0:
			driver_peer_id = passengers[0].get_multiplayer_authority()
			set_multiplayer_authority(driver_peer_id)
			sync_driver.rpc(player.get_path())
		else:
			driver_peer_id = -1
			clear_driver.rpc()
	print(player.name + " left")
	player.exit_boat.rpc()


@rpc("authority", "call_local", "reliable")
func sync_authority(peer_id: int):
	set_multiplayer_authority(peer_id)

@rpc("authority", "call_local", "reliable")
func sync_driver(peer_id: int):
	driver_peer_id = peer_id
	
@rpc("authority", "call_local", "reliable")
func clear_driver():
	driver_peer_id = -1
