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
		
		add_number_label(slot_ui, i - start_slot + 1)

#add small number to each hotbar slot
func add_number_label(slot_ui : Control, number : int):
	var label = Label.new()
	label.text = str(number)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_right = -4    # padding from right edge
	label.offset_bottom = -2   # padding from bottom edge
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # so clicks still reach the slot
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	slot_ui.add_child(label)

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
