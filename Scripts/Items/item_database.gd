extends Node

var items := {}
var crafts := {}

#preload everything
func _ready():
	register_item(preload("res://Resources/Items/Materials/Stone.tres"))
	register_item(preload("res://Resources/Items/Materials/Wood.tres"))
	register_item(preload("res://Resources/Items/Materials/BoatProtectionBerry.tres"))
	register_item(preload("res://Resources/Items/Placeables/workbench.tres"))
	register_item(preload("res://Resources/Items/Placeables/boat_workbench.tres"))
	register_item(preload("res://Resources/Items/Tools/Axe.tres"))
	register_item(preload("res://Resources/Items/Tools/Pickaxe.tres"))
	register_item(preload("res://Resources/Items/Placeables/Boat.tres"))

	register_craft(preload("res://Resources/Recipes/Placeables/Crafting stations/BoatWorkbenchCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Placeables/Crafting stations/WorkbenchCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/AxeCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Player items and gear/PickaxeCraft.tres"))
	register_craft(preload("res://Resources/Recipes/Placeables/BoatCraft.tres"))
	
	register_upgrade(preload("res://Resources/Recipes/Boat Upgrades/LavaBoatUpgradeCraft.tres"))

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
