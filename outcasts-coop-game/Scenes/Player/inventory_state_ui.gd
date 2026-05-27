class_name InventoryUIController
extends CanvasLayer

@onready var hotbarUI = $HotbarUI
@onready var inventoryUI = $InventoryOpenUI
@onready var craftingUI = $CraftingUI

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
			craftingUI.visible = false
		UIState.inventory_open:
			hotbarUI.visible = true
			inventoryUI.visible = true
			craftingUI.visible = true
