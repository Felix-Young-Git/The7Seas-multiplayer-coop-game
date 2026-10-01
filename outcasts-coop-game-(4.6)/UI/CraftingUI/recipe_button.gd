class_name RecipeButton
extends Button

var inventory : Inventory
var recipe : CraftGeneral

func set_recipe(new_recipe : CraftGeneral, player_inventory : Inventory):
	recipe = new_recipe
	inventory = player_inventory
	
	if recipe is CraftRecipe:
		text = recipe.output_item.item_id
		icon = recipe.output_item.icon
	elif recipe is UpgradeRecipe:
		text = recipe.upgrade_name
	disabled = !inventory.can_craft(recipe)
	
	inventory.UpdatedInventory.connect(refresh)


func refresh():
	disabled = !inventory.can_craft(recipe)
