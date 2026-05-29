extends Node

var items := {}
var crafts := {}

func _ready():
	register_item(preload("res://Resources/Items/Materials/Stone.tres"))
	register_item(preload("res://Resources/Items/Materials/Wood.tres"))
	register_item(preload("res://Resources/Items/Placeables/workbench.tres"))
	register_item(preload("res://Resources/Items/Tools/Axe.tres"))
	register_item(preload("res://Resources/Items/Tools/Pickaxe.tres"))

	register_craft(preload("res://Resources/Recipes/Placeables/Crafting stations/WorkbenchCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/AxeCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/PickaxeCraft.tres"))

func register_item(item : ItemData):
	items[item.item_id] = item

func get_item(id : String) -> ItemData:
	return items.get(id)

func register_craft(craft_recipe : CraftRecipe):
	crafts[craft_recipe.recipe_id] = craft_recipe

func get_craft(id : String) -> CraftRecipe:
	return crafts.get(id)
