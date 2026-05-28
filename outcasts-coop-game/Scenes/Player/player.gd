class_name Player
extends CharacterBody2D

#tools
@export var current_tool: DataTypes.Tools = DataTypes.Tools.None

@onready var hotbarUI = $InventoryUI/HotbarUI/Panel/GridContainer
@onready var camera = $Camera2D
@onready var inventory = %Inventory
@onready var inventoryUI = $InventoryUI

var nearby_stations : Array[String] = []
var inventory_open : bool 
var hotbar_size : int = 9
var selected_slot : int = 0 #start by having the first slot in inventory selected
var player_direction: Vector2

func _enter_tree() -> void:
	var id = name.to_int()
	set_multiplayer_authority(id)
	
	if has_node("%Inventory"):
		%Inventory.owner_peer_id = id
	

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority():
		camera.enabled = true
		camera.make_current()
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
		selected_slot = wrapi(selected_slot - 1, 0, 8)

	if event.is_action_pressed("Wheel Down"):
		selected_slot = wrapi(selected_slot + 1, 0, 8)

	#set selected
	for i in range(hotbarUI.get_child_count()):
		if i == (selected_slot):
			hotbarUI.get_child(i).set_selected(true)
		else:
			hotbarUI.get_child(i).set_selected(false)
	
	#set current tool
	var current_item = inventory.item_slots[selected_slot].item
	if current_item is ToolItemData:
		var current_tool_name = current_item.display_name
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
			placeable_item.resource_path,
			get_global_mouse_position()
		)

@rpc("any_peer", "call_local")
func request_place(item_path : String, world_position : Vector2):
	if !multiplayer.is_server():
		return
	var sender = multiplayer.get_remote_sender_id()
	var player = get_player_from_peer(sender)

	if !player:
		return
	if !is_instance_valid(player):
		return
	var item = load(item_path) as PlaceableItemData
	#this is returning false on the client so need to fix for multiplayer, should just switch to item_ids
	print(player.inventory.has_item(item))
	# Validate player actually has item
	if !player.inventory.has_item(item):
		return
	print("5")
	# Spawn object
	var obj = item.placeable_scene.instantiate()
	get_tree().current_scene.add_child(obj)
	var tile_size = 16
	world_position = world_position.snapped(Vector2.ONE * tile_size)
	obj.global_position = world_position
	

	# Remove item from inventory
	player.inventory.remove_item(item)


func get_player_from_peer(peer_id : int) -> Player:
	for player in get_tree().get_nodes_in_group("players"):
		if player.get_multiplayer_authority() == peer_id:
			return player
	
	return null
