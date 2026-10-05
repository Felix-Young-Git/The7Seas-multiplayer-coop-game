class_name Inventory
extends Node

class ItemSlot:
	var item : ItemData
	var quantity : int

signal UpdatedInventory
signal UpdatedSlot (slot : ItemSlot)

var owner_peer_id : int = 1
var item_slots : Array[ItemSlot]

@export var size : int = 18
@export var start_items : Dictionary[ItemData, int]
@export var workbench_crafting_station : ItemData

func _ready() -> void:
	#create slots
	for i in range(size):
		item_slots.append(ItemSlot.new())
	
	#add start items
	for key in start_items:
		for i in range(start_items[key]):
			add_item(key)


#ITEM-INVENTORY INTERACTIONS-----------------------------------------------------------------------
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
		
		slot.item = item      #COULD BE AN ISSUE MIGHT HAVE TO SWITCH TO USE ITEM IDS 
		slot.quantity = 1 
		slot_index = item_slots.find(slot)

	UpdatedInventory.emit()
	UpdatedSlot.emit(slot)

	# If we are the server, sync this specific slot index down to the client
	if multiplayer.is_server() and slot_index != -1:		
		if owner_peer_id > 0:
			# Send only to that specific player's client
			sync_inventory()
	return true

#removes an item from the inventory
func remove_item (item : ItemData):
	if not has_item(item.item_id):
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
		var player_node = get_parent()
		if player_node.has_method("get_multiplayer_authority"):
			sync_inventory()

#returns an item slot containing the specified item
func get_item_slot (item : ItemData) -> ItemSlot:
	for slot in item_slots:
		if slot.item == null:
			continue
		if slot.item.item_id == item.item_id:
			return slot
	return null

#returns an item slot with no item in it
func get_empty_item_slot () -> ItemSlot:
	for slot in item_slots:
		if slot.item == null:
			return slot
	return null

# is this item in the inventory?
func has_item (item_id : String) -> bool:
	for slot in item_slots:
		if slot.item == null:
			continue
		if slot.item.item_id == item_id:
			return true
	return false
	
#get the total number of an item in inventory
func get_item_count(item : ItemData) -> int:
	var total := 0
	for slot in item_slots:
		if slot.item == null:
			continue
		if slot.item.item_id == item.item_id:
			total += slot.quantity
	return total

#swap to slots' items - DOESN'T WORK WHEN INVENTORY OPEN?
func swap_slots(index_a : int, index_b : int):
	if index_a == index_b:
		return

	var slot_a = item_slots[index_a]
	var slot_b = item_slots[index_b]

	# Swap item -  COULD BE A PROBLEM MIGHT NEED TO SWITCH TO USE IDEM IDS
	var temp_item = slot_a.item
	slot_a.item = slot_b.item
	slot_b.item = temp_item

	# Swap quantity
	var temp_quantity = slot_a.quantity
	slot_a.quantity = slot_b.quantity
	slot_b.quantity = temp_quantity

	UpdatedInventory.emit()

	UpdatedSlot.emit(slot_a)
	UpdatedSlot.emit(slot_b)
#--------------------------------------------------------------------------------------------


#CRAFTING-------------------------------------------------------------------------
func can_craft(recipe : CraftGeneral)->bool:
	
	if recipe == null:
		return false
	
	#check ingredients
	for ingredient in recipe.ingredients:
		var required_amount : int = recipe.ingredients[ingredient]
		var inventory_amount : int = get_item_count(ingredient)
		
		if inventory_amount < required_amount:
			return false
	#check stations
	var player_node = get_parent()
		
	for station in recipe.required_stations:
		if !player_node.nearby_stations.has(station):
			return false
	
	if recipe is UpgradeRecipe:
		var workbench = player_node.get_station_node("boat_workbench")
		if workbench == null or workbench.get_nearby_boat() == null:
			return false
	return true

func craft(recipe : CraftGeneral):
	if !can_craft(recipe):
		return

	if recipe is UpgradeRecipe:
		var module : BoatModule = null
		if recipe.upgrade_name == "Boat Heat Coating":
			module = FireProtectionModule.new()
		if module == null:
			return
		var workbench = get_parent().get_station_node("boat_workbench")
		if !workbench.craft_upgrade(module):
			return  # install failed, so don't consume ingredients
			
	for ingredient in recipe.ingredients:
		var amount_to_remove : int = recipe.ingredients[ingredient]
		for i in range(amount_to_remove):
			remove_item(ingredient)

	if recipe is CraftRecipe:
		for i in range(recipe.output_amount):
			add_item(recipe.output_item)
#--------------------------------------------------------------------------------------------


#SYNC INVENTORY-----------------------------------------------------------------------------
func sync_inventory():
	if !multiplayer.is_server():
		return

	var data = []
	for slot in item_slots:
		if slot.item:
			data.append({
				"id": slot.item.item_id,
				"quantity": slot.quantity
			})
		else:
			data.append({
				"id": "",
				"quantity": 0
			})
	sync_inventory_data.rpc_id(owner_peer_id, data)
	
@rpc( "reliable", "any_peer")
func sync_inventory_data(data : Array):
	for i in range(data.size()):
		var slot_data = data[i]
		var slot = item_slots[i]

		if slot_data["id"] == "":
			slot.item = null
			slot.quantity = 0
		else:
			slot.item = ItemDatabase.get_item(slot_data["id"])
			slot.quantity = slot_data["quantity"]

	UpdatedInventory.emit()
#--------------------------------------------------------------------------------------------
