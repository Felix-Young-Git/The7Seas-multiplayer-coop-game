extends Node

var items := {}
var crafts := {}

#preload everything
func _ready():
	register_item(preload("res://Resources/Items/Materials/stone.tres"))
	register_item(preload("res://Resources/Items/Materials/wood.tres"))
	register_item(preload("res://Resources/Items/Materials/boat_protection_berry.tres"))
	register_item(preload("res://Resources/Items/Placeables/workbench.tres"))
	register_item(preload("res://Resources/Items/Placeables/boat_workbench.tres"))
	register_item(preload("res://Resources/Items/Tools/axe.tres"))
	register_item(preload("res://Resources/Items/Tools/pickaxe.tres"))
	register_item(preload("res://Resources/Items/Placeables/boat.tres"))

	register_craft(preload("res://Resources/Recipes/Placeables/Crafting stations/boat_workbench_craft.tres"))
	register_craft(preload("res://Resources/Recipes/Placeables/Crafting stations/workbench_craft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/axe_craft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/pickaxe_craft.tres"))
	register_craft(preload("res://Resources/Recipes/Placeables/boat_craft.tres"))
	
	register_upgrade(preload("res://Resources/Recipes/Boat Upgrades/lava_boat_upgrade_craft.tres"))

#register and be able to get everything via strings
func register_item(item : ItemData):
	items[item.item_id] = item

func get_item(id : String) -> ItemData:
	return items.get(id)

func register_upgrade(craft_upgrade : UpgradeRecipe):
	crafts[craft_upgrade.recipe_id] = craft_upgrade
	
func register_craft(craft_recipe : CraftRecipe):
	crafts[craft_recipe.recipe_id] = craft_recipe

func get_craft(id : String) -> CraftGeneral:
	return crafts.get(id)
