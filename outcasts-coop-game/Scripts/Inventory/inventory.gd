class_name Inventory
extends Node

class ItemSlot:
	var item : ItemData
	var quantity : int

signal UpdatedInventory
signal UpdatedSlot (slot : ItemSlot)

var owner_peer_id : int = 1
var item_slots : Array[ItemSlot]

@export var size : int = 9
@export var start_items : Dictionary[ItemData, int]

func _ready() -> void:
	#create slots
	for i in range(size):
		item_slots.append(ItemSlot.new())
	
	#add start items
	for key in start_items:
		for i in range(start_items[key]):
			add_item(key)

#adds an item to inventory
func add_item (item : ItemData) -> bool:
	var slot : ItemSlot = get_item_slot(item)
	var slot_index: int = -1
	
	if slot and slot.quantity < item.max_stack_size:
		slot.quantity += 1
		slot_index = item_slots.find(slot)
	else:
		slot = get_empty_item_slot()
		
		if not slot:
			return false
		
		slot.item = item
		slot.quantity = 1 
		slot_index = item_slots.find(slot)

	UpdatedInventory.emit()
	UpdatedSlot.emit(slot)

	# If we are the server, sync this specific slot index down to the client
	if multiplayer.is_server() and slot_index != -1:
		var item_path = item.resource_path if item else ""
		
		if owner_peer_id > 0:
			# Send only to that specific player's client
			sync_slot_update.rpc_id(owner_peer_id, slot_index, item_path, slot.quantity)

	return true

#removes an item from the inventory
func remove_item (item : ItemData):
	if not has_item(item):
		return
	
	var slot : ItemSlot = get_item_slot(item)
	remove_item_from_slot(slot)

#removes an item from the specified slot
func remove_item_from_slot (slot : ItemSlot):
	if not slot.item:
		return
	
	var slot_index = item_slots.find(slot)
	
	if slot.quantity == 1:
		slot.item = null
		slot.quantity = 0
	else:
		slot.quantity -= 1
	
	UpdatedInventory.emit()
	UpdatedSlot.emit(slot) 
	
	if multiplayer.is_server() and slot_index != -1:
		var item_path = slot.item.resource_path if slot.item else ""
		var player_node = get_parent()
		if player_node.has_method("get_multiplayer_authority"):
			var peer_id = player_node.get_multiplayer_authority()
			sync_slot_update.rpc_id(peer_id, slot_index, item_path, slot.quantity)

#returns an item slot containing the specified item
func get_item_slot (item : ItemData) -> ItemSlot:
	for slot in item_slots:
		if slot.item == item:
			return slot
	
	return null

#returns an item slot with no item in it
func get_empty_item_slot () -> ItemSlot:
	for slot in item_slots:
		if slot.item == null:
			return slot
	
	return null

# is this item in the inventory?
func has_item (item : ItemData) -> bool:
	for slot in item_slots:
		if slot.item == item:
			return true
	
	return false
	

# The server calls this to force a specific client to update a slot
@rpc("any_peer", "call_remote", "reliable")
func sync_slot_update(slot_index: int, item_path: String, quantity: int) -> void:
	var slot = item_slots[slot_index]
	if item_path == "":
		slot.item = null
	else:
		# Load the resource resource from its file path
		slot.item = load(item_path) as ItemData
	
	slot.quantity = quantity
	
	# Trigger your existing signals to refresh the UI!
	UpdatedInventory.emit()
	UpdatedSlot.emit(slot)
