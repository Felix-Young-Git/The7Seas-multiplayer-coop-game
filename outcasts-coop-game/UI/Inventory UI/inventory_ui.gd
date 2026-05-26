extends Control


@export var slot_scene : PackedScene
@export var start_slot : int = 0 
@export var end_slot : int = 8


@onready var grid = $Panel/GridContainer
@onready var inventory : Inventory = get_parent().get_node("%Inventory")

var slot_uis = []

func _ready():
	create_slots()

	inventory.UpdatedInventory.connect(update_inventory)

func create_slots():
	
	print(name, " Start: ", start_slot, " End: ", end_slot)
	
	for i in range(start_slot, end_slot + 1):
		
		print("Creating slot ", i)
		
		if i >= inventory.item_slots.size():
			break
		
		var slot = inventory.item_slots[i]
		var slot_ui = slot_scene.instantiate()
		
		grid.add_child(slot_ui)
		slot_ui.set_slot(slot)
		
		slot_uis.append(slot_ui)

func update_inventory():
	for i in range(slot_uis.size()):
		slot_uis[i].update_visuals()
