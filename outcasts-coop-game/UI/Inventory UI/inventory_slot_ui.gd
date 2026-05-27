extends Panel

@onready var icon = $TextureRect
@onready var quantity_label = $Label

signal slot_clicked(index)

var slot : Inventory.ItemSlot
var slot_index : int
var inventory : Inventory

func set_slot(new_slot : Inventory.ItemSlot, index : int, inv : Inventory):
	slot = new_slot
	slot_index = index
	inventory = inv
	update_visuals()

func update_visuals():
	if slot.item:
		icon.texture = slot.item.icon
		icon.visible = true
		
		if slot.quantity > 1:
			quantity_label.text = str(slot.quantity)
		else:
			quantity_label.text = ""
	else:
		icon.visible = false
		quantity_label.text = ""

#detect slot clicked
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_index)

#change color of selected slot
func set_selected(selected : bool):
	if selected:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE
