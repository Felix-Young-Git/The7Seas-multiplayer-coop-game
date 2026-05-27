class_name RecipeButton
extends Button

var inventory : Inventory
var recipe : CraftRecipe

func set_recipe(new_recipe : CraftRecipe, player_inventory : Inventory):
	recipe = new_recipe
	inventory = player_inventory
	text = recipe.output_item.display_name
	icon = recipe.output_item.icon
	disabled = !inventory.can_craft(recipe)
	
	inventory.UpdatedInventory.connect(refresh)


func refresh():
	disabled = !inventory.can_craft(recipe)
