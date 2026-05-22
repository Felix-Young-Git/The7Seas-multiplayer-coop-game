extends Panel

@onready var icon = $TextureRect
@onready var quantity_label = $Label

var slot : Inventory.ItemSlot

func set_slot(new_slot : Inventory.ItemSlot):
	slot = new_slot
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

#change color of selected slot
func set_selected(selected : bool):
	if selected:
		modulate = Color.YELLOW
	else:
		modulate = Color.WHITE
