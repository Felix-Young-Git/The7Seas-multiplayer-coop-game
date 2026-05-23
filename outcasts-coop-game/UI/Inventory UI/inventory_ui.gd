extends Control


@export var slot_scene : PackedScene

@onready var grid = $Panel/GridContainer
@onready var inventory : Inventory = get_parent().get_node("%Inventory")

var slot_uis = []

func _ready():
	create_slots()

	inventory.UpdatedInventory.connect(update_inventory)

func create_slots():
	for slot in inventory.item_slots:
		var slot_ui = slot_scene.instantiate()
		
		grid.add_child(slot_ui)
		slot_ui.set_slot(slot)
		
		slot_uis.append(slot_ui)

func update_inventory():
	for i in range(slot_uis.size()):
		slot_uis[i].update_visuals()
