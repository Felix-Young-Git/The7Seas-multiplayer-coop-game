class_name Boat
extends CharacterBody2D

var boat_speed := 300.0

var driver_peer_id : int = -1
var passengers : Array[Player] = []
var nearby_players: Array[Player] = []

#boats should initially collide with lava
func _ready() -> void:
	set_collision_mask_value(9, true)

#boat exit stuff
@onready var tilemap = get_tree().get_first_node_in_group("tilemap")
@export var exit_check_radius : float = 32.0
@export var exit_sample_points : int = 8

var modules : Array[BoatModule] = []


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
	
	for module in modules:
		boat_speed = module.modify_speed(boat_speed, self)
	
	velocity = direction * boat_speed
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
	
	sync_driver.rpc(driver_peer_id)
	
	set_multiplayer_authority(driver_peer_id)
	sync_authority.rpc(driver_peer_id)

	print(player.name + " boarded")
	player.enter_boat.rpc(get_path())


func find_valid_exit_point():
	#print("running find exit point")
	var origin = global_position
	var best_point = null
	var best_dist = INF
	for i in range(exit_sample_points):
		var angle = TAU * i / exit_sample_points
		var candidate = origin + Vector2(cos(angle), sin(angle)) * exit_check_radius

		if is_land_at(candidate):
			var d = origin.distance_to(candidate)
			if d < best_dist:
				best_dist = d
				best_point = candidate

	return best_point

func is_land_at(world_pos: Vector2):
	#print("running is land at")
	#gets the first child of the tilemap node, which is the water tile map layer
	var water_tilemap = tilemap.get_child(1)  
	var map_coords = water_tilemap.local_to_map(
		water_tilemap.to_local(world_pos)
	)
	var tile_data = water_tilemap.get_cell_tile_data(map_coords)
	#the only tile data I have in when writing this is water, so if the tile 
	#doesn't have that then it is land
	#the comment is what I changed it from, not sure why it needs to be !=, also might need
	#to make it not spawn the player in objects
	if tile_data != null: # ==
		return true  # empty cell = not water = treat as land
	return false

func unboard(player: Player) -> void:
	if !multiplayer.is_server():
		return
	if !(player.current_boat == self):
		return
		
	#Check if land is nearby so the player can exit on the land
	var exit_pos = find_valid_exit_point()
	if exit_pos == null:
		print("no land nearby")
		return
	
	player.global_position = exit_pos
	
	
	#this needs to go once the new exit mechanic is in
	#var spawn_pos = global_position + Vector2(64, 0)
	#player.global_position = spawn_pos
	
	#leave this
	passengers.erase(player)
	player.current_boat = null
	
	if driver_peer_id == player.get_multiplayer_authority():
		if passengers.size() > 0:
			driver_peer_id = passengers[0].get_multiplayer_authority()
			sync_driver.rpc(driver_peer_id)
			set_multiplayer_authority(driver_peer_id)
			sync_authority.rpc(driver_peer_id)
		else:
			driver_peer_id = -1
			clear_driver.rpc()
			set_multiplayer_authority(1)
			sync_authority.rpc(1)
		
			
			
	print(player.name + " left")
	player.exit_boat.rpc(exit_pos)


@rpc("any_peer", "call_local", "reliable")
func sync_authority(peer_id: int):
	set_multiplayer_authority(peer_id)
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(peer_id)

@rpc("any_peer", "call_local", "reliable")
func sync_driver(peer_id: int):
	driver_peer_id = peer_id
	
@rpc("any_peer", "call_local", "reliable")
func clear_driver():
	driver_peer_id = -1
	

# map ids to module classes (add new upgrades here)
func _create_module(id : String) -> BoatModule:
	match id:
		"fire_protection":
			return FireProtectionModule.new()
	return null



# server-side entry point (called from the workbench)
func install_upgrade(module: BoatModule):
	if !multiplayer.is_server():
		return
	apply_upgrade.rpc(module.module_id)

func remove_upgrade(module: BoatModule):
	if !multiplayer.is_server():
		return
	remove_upgrade_rpc.rpc(module.module_id)

# runs on the server AND every client, each building its own module
@rpc("authority", "call_local", "reliable")
func apply_upgrade(id : String):
	var module = _create_module(id)
	if module == null:
		return
	modules.append(module)
	module.modify_boat_visuals(self)
	module.modify_collision(self)

@rpc("authority", "call_local", "reliable")
func remove_upgrade_rpc(id : String):
	for module in modules:
		if module.module_id == id:
			modules.erase(module)
			break
