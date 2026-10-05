class_name Player
extends CharacterBody2D

@export var current_tool: DataTypes.Tools = DataTypes.Tools.None
@onready var tilemap = get_tree().get_first_node_in_group("tilemap")
@onready var hotbarUI = $InventoryUI/HotbarUI/Panel/GridContainer
@onready var camera = $Camera2D
@onready var inventory = %Inventory
@onready var inventoryUI = $InventoryUI

@export var grid_size: Vector2 = Vector2(16, 16)
@export var snap_to_grid: bool = true

var ghost: Node2D = null
var ghost_item: PlaceableItemData = null
var nearby_stations : Array[String] = []
var nearby_station_nodes : Dictionary = {}
var inventory_open : bool 
var hotbar_size : int = 9
var selected_slot : int = 0
var last_selected_slot : int = -1
var player_direction: Vector2
var current_boat : Boat = null
var boat
var in_boat := false
var camera_target: Node2D
var MAX_PLACE_DISTANCE = 500


func _enter_tree() -> void:
	var id = name.to_int()
	set_multiplayer_authority(id)
	
	if has_node("%Inventory"):
		var inventory_node = get_node("%Inventory")
		inventory_node.owner_peer_id = id
		inventory_node.set_multiplayer_authority(id)
	

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
		camera_target = self
		inventoryUI.visible = true
		inventoryUI.set_state(inventoryUI.UIState.hotbar)
		inventory_open = false
		inventory.UpdatedInventory.connect(refresh_selection)
		refresh_selection()
	else:
		camera.enabled = false
		inventoryUI.visible = false


func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return
	
	if event.is_action_pressed("Interact"):
		try_interact_boat()
	
	#place items
	if event.is_action_pressed("Place"):
		try_place_current_item()
	
	#inventory
	if event.is_action_pressed("Inventory"):
		if inventory_open == false:
			inventory_open = true
			inventoryUI.set_state(inventoryUI.UIState.inventory_open)
		else:
			inventory_open = false
			inventoryUI.set_state(inventoryUI.UIState.hotbar)

	#Selected slot from key press
	if event.is_action_pressed("Hotbar1"):
		selected_slot = 0
	if event.is_action_pressed("Hotbar2"):
		selected_slot = 1
	if event.is_action_pressed("Hotbar3"):
		selected_slot = 2
	if event.is_action_pressed("Hotbar4"):
		selected_slot = 3
	if event.is_action_pressed("Hotbar5"):
		selected_slot = 4
	if event.is_action_pressed("Hotbar6"):
		selected_slot = 5
	if event.is_action_pressed("Hotbar7"):
		selected_slot = 6
	if event.is_action_pressed("Hotbar8"):
		selected_slot = 7
	if event.is_action_pressed("Hotbar9"):
		selected_slot = 8
	
	#scroll wheel 
	if event.is_action_pressed("Wheel Up"):
		selected_slot = wrapi(selected_slot - 1, 0, 9)
	if event.is_action_pressed("Wheel Down"):
		selected_slot = wrapi(selected_slot + 1, 0, 9)
		
	#if selected slot changed, update
	if selected_slot != last_selected_slot:
		last_selected_slot = selected_slot
		refresh_selection()

#GHOST PREVIEW AND PLACING ITEMS------------------------------------------------------------------
func refresh_selection() -> void:
	# highlight the hotbar slot
	for i in range(hotbarUI.get_child_count()):
		hotbarUI.get_child(i).set_selected(i == selected_slot)

	var item : ItemData = inventory.item_slots[selected_slot].item

	# tool
	current_tool = DataTypes.Tools.None
	if item is ToolItemData:
		match item.item_id:
			"Axe": current_tool = DataTypes.Tools.Axe
			"Pickaxe": current_tool = DataTypes.Tools.Pickaxe

	# ghost
	if item is PlaceableItemData:
		if ghost_item != item:  # don't rebuild if it's already the right ghost
			start_placing(item)
	else:
		cancel_placing()

func start_placing(item: PlaceableItemData) -> void:
	cancel_placing()
	if item == null or item.placeable_scene == null:
		return
	ghost_item = item
	ghost = item.placeable_scene.instantiate()
	ghost.set("is_ghost", true)  # optional flag, see note below
	ghost.modulate = Color(1, 1, 1, 0.5)
	ghost.z_index = 100
	ghost.process_mode = Node.PROCESS_MODE_DISABLED
	ghost.top_level = true          # use global coordinates, ignore the player's transform
	_disable_collisions(ghost)
	add_child(ghost)   

func try_place_current_item():
	var slot = inventory.item_slots[selected_slot]

	if !slot.item:
		return

	if slot.item is PlaceableItemData:
		var placeable_item = slot.item as PlaceableItemData
		request_place.rpc_id(
			1,
			placeable_item.item_id,
			get_global_mouse_position()
		)

@rpc("any_peer","call_local", "reliable")
func request_place(item_id : String, world_position : Vector2):
	if !multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	if sender == 0:
		sender = 1
	var player = get_player_from_peer(sender)

	if !player:
		return
	if !is_instance_valid(player):
		return
	var item = ItemDatabase.get_item(item_id)
	
	# Validate player actually has item
	if !player.inventory.has_item(item.item_id):
		return

	#Check if invalid location to place
	if item_id == "Boat":
		if tilemap.is_water_tile(world_position) == false:
			return
	else:
		if tilemap.is_water_tile(world_position) == true:
			return

	#Stop the player from placing it super far away
	if player.global_position.distance_to(world_position) > MAX_PLACE_DISTANCE:
		return

	#create the opject
	var spawn_node = get_tree().current_scene.get_node("/root/Game")
	var obj = item.placeable_scene.instantiate()
	obj.name = item_id + "_" + str(Time.get_ticks_usec())
	var tile_size = 16
	world_position = world_position.snapped(Vector2.ONE * tile_size)
	obj.global_position = world_position
	spawn_node.add_child(obj)
	
	# Remove item from inventory
	player.inventory.remove_item(item)


func cancel_placing() -> void:
	if ghost:
		ghost.queue_free()
	ghost = null
	ghost_item = null

func _process(_delta: float) -> void:
	if not ghost:
		return
	# Hide the ghost while the mouse is over inventory/UI
	var over_ui := get_viewport().gui_get_hovered_control() != null
	ghost.visible = not over_ui

	var pos := get_global_mouse_position()
	if snap_to_grid:
		pos = pos.snapped(grid_size)
	ghost.global_position = pos

func _unhandled_input(event: InputEvent) -> void:
	if not ghost:
		return
	if event.is_action_pressed("place"):
		request_place.rpc_id(1, ghost_item.item_id, ghost.global_position)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		cancel_placing()

func _disable_collisions(node: Node) -> void:
	if node is CollisionObject2D:
		node.collision_layer = 0
		node.collision_mask = 0
	for child in node.get_children():
		_disable_collisions(child)
#--------------------------------------------------------------------------------------------


#STATIONS-----------------------------------------------------------------------------------
#called when entering/exiting a workbench area, currently have workbench and boat_workbench
func add_station(station_id : String, station_node : Node = null ):
	if station_node:
		nearby_station_nodes[station_id] = station_node
	if !nearby_stations.has(station_id):
		nearby_stations.append(station_id)
	inventory.UpdatedInventory.emit()

func remove_station(station_id : String, station_node : Node = null):
	# only clear if it's the same bench we're leaving (handles overlapping benches)
	if station_node == null or nearby_station_nodes.get(station_id) == station_node:
		nearby_station_nodes.erase(station_id)
		nearby_stations.erase(station_id)
	inventory.UpdatedInventory.emit()

func get_station_node(station_id : String) -> Node:
	return nearby_station_nodes.get(station_id)
#--------------------------------------------------------------------------------------------

#GET A PLAYER FORM PEER_ID-----------------------------------------------------------------
func get_player_from_peer(peer_id : int) -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.get_multiplayer_authority() == peer_id:
			return player
	return null
#--------------------------------------------------------------------------------------------

#CRAFTING------------------------------------------------------------------------------------
func send_craft_request(recipe_id : String):
	request_craft_server.rpc_id(1, recipe_id)

@rpc("any_peer","call_local",  "reliable")
func request_craft_server(recipe_id: String):
	if !multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	#Ensure the sender actually owns this player character
	if sender != get_multiplayer_authority():
		return

	var recipe = ItemDatabase.get_craft(recipe_id)
	if !recipe:
		return
		
	if inventory:
		inventory.craft(recipe)
#--------------------------------------------------------------------------------------------

#BOATS---------------------------------------------------------------------------------------
func try_interact_boat():
	if !in_boat:
		for area in $InteractionArea.get_overlapping_areas():
			var boat = area.get_parent()
			if boat is Boat:
				request_boat_interaction.rpc_id(
					1,
					boat.get_path()
				)
				return
	else:
		request_boat_interaction.rpc_id(
			1,
			current_boat.get_path()
		)
@rpc("any_peer","call_local","reliable")
func request_boat_interaction(boat_path: NodePath):
	if !multiplayer.is_server():
		return

	var sender = multiplayer.get_remote_sender_id()
	var player = get_player_from_peer(sender)
	
	var boat = get_node(boat_path)
	boat.interact(player)

#set the players boat, then remove the player from the scene basically, and set the camera on the boat
@rpc("any_peer","call_local","reliable")
func enter_boat(boat_path: NodePath):
	current_boat = get_node(boat_path)
	visible = false
	in_boat = true
	camera_target = current_boat
	$CollisionShape2D.disabled = true

#reposition and turn the player back on and reset camer
@rpc("any_peer","call_local","reliable")
func exit_boat(spawn_position: Vector2):
	global_position = spawn_position
	visible = true
	in_boat = false
	camera_target = self
	$CollisionShape2D.disabled = false
	current_boat = null
#--------------------------------------------------------------------------------------------
