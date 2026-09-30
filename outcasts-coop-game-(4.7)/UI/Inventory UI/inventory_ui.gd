extends Control


@export var slot_scene : PackedScene
@export var start_slot : int = 0 
@export var end_slot : int = 8

@onready var grid = $Panel/GridContainer
@onready var inventory : Inventory = get_parent().get_node("%Inventory")

var slot_uis = []
var selected_slot_index : int = -1

func _ready():
	create_slots()
	inventory.UpdatedInventory.connect(update_inventory)

func create_slots():
	for i in range(start_slot, end_slot + 1):
		
		if i >= inventory.item_slots.size():
			break
		
		var slot = inventory.item_slots[i]
		var slot_ui = slot_scene.instantiate()
		
		grid.add_child(slot_ui)
		slot_ui.set_slot(slot, i, inventory)
		slot_ui.slot_clicked.connect(on_slot_clicked)
		slot_uis.append(slot_ui)

func update_inventory():
	for i in range(slot_uis.size()):
		slot_uis[i].update_visuals()

#If one slot clicked, save slot. If second clicked then swap and reset
func on_slot_clicked(clicked_index : int):
	if selected_slot_index == -1:
		selected_slot_index = clicked_index
		return
	
	inventory.swap_slots(selected_slot_index, clicked_index)
	selected_slot_index = -1
