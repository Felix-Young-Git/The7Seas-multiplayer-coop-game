class_name InventoryUIController
extends CanvasLayer

@onready var hotbarUI = $HotbarUI
@onready var inventoryUI = $InventoryOpenUI

#ui states
enum UIState {
	hotbar,
	inventory_open
}


func set_state(state: UIState):
	match state:
		UIState.hotbar:
			hotbarUI.visible = true
			inventoryUI.visible = false
		UIState.inventory_open:
			hotbarUI.visible = true
			inventoryUI.visible = true
