class_name Player
extends CharacterBody2D

#tools
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

@onready var tilemap = get_tree().get_first_node_in_group("tilemap")
@onready var hotbarUI = $InventoryUI/HotbarUI/Panel/GridContainer
@onready var camera = $Camera2D
@onready var inventory = %Inventory
@onready var inventoryUI = $InventoryUI

var nearby_stations : Array[String] = []
var inventory_open : bool 
var hotbar_size : int = 9
var selected_slot : int = 0 #start by having the first slot in inventory selected
var player_direction: Vector2
var current_boat : Boat = null
var boat
var in_boat := false
var camera_target: Node2D
var MAX_PLACE_DISTANCE = 1000

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

		
	else:
		camera.enabled = false
		inventoryUI.visible = false


#input for selected slot (PROBABLY SHOULD MOVE TO INPUT EVENTS SCRIPT AT SOME POINT)
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

	#numbers
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

	#set selected
	for i in range(hotbarUI.get_child_count()):
		if i == (selected_slot):
			hotbarUI.get_child(i).set_selected(true)
		else:
			hotbarUI.get_child(i).set_selected(false)
	
	#set current tool
	var current_item = inventory.item_slots[selected_slot].item
	if current_item is ToolItemData:
		var current_tool_name = current_item.item_id
		if current_tool_name == "Axe":
			current_tool = DataTypes.Tools.Axe
		if current_tool_name == "Pickaxe":
			current_tool = DataTypes.Tools.Pickaxe
	else:
		current_tool = DataTypes.Tools.None

#called went entering/exiting a workbench area
func add_station(station_id : String):
	if !nearby_stations.has(station_id):
		nearby_stations.append(station_id)
		inventory.UpdatedInventory.emit()

func remove_station(station_id : String):
	nearby_stations.erase(station_id)
	inventory.UpdatedInventory.emit()

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
	var player = get_player_from_peer(sender)

	if !player:
		return
	if !is_instance_valid(player):
		return
	var item = ItemDatabase.get_item(item_id)
	
	# Validate player actually has item
	if !player.inventory.has_item(item.item_id):
		return

	#If placing boat then check if placing in water
	if item_id == "Boat":
		if tilemap.is_water_tile(world_position) == false:
			return

	#Stop the player from placing it super far away
	if player.global_position.distance_to(world_position) > MAX_PLACE_DISTANCE:
		return

	var spawn_node = get_tree().current_scene.get_node("/root/InventoryTest")
	var obj = item.placeable_scene.instantiate()
	obj.name = item_id + "_" + str(Time.get_ticks_usec())
	var tile_size = 16
	world_position = world_position.snapped(Vector2.ONE * tile_size)
	obj.global_position = world_position
	
	spawn_node.add_child(obj)
	
	# Remove item from inventory
	player.inventory.remove_item(item)


func get_player_from_peer(peer_id : int) -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.get_multiplayer_authority() == peer_id:
			return player
	return null


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

#boats - NEED TO CHANGE TO USE RPC's SO THAT WORKS FOR MULTIPLAYER as right now the player
#		doesn't appear to enter the boat on the client's screen and then teleports when
#		 the host exits, also the client can't control the boat when they enter and are 
#		the only one in the boat - this happened after the host had entered and exited 
#		befroe the client entered
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
