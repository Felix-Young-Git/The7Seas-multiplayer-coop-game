class_name RecipeRow
extends HBoxContainer

signal pressed

@onready var button : Button = $Button
@onready var ingredients_label : RichTextLabel = $IngredientsLabel

var inventory : Inventory
var recipe : CraftGeneral

func _ready() -> void:
	button.pressed.connect(func(): pressed.emit())

func set_recipe(new_recipe : CraftGeneral, player_inventory : Inventory) -> void:
	recipe = new_recipe
	inventory = player_inventory
	
	if recipe is CraftRecipe:
		button.text = recipe.output_item.item_id
		button.icon = recipe.output_item.icon
	elif recipe is UpgradeRecipe:
		button.text = recipe.upgrade_name
	
	inventory.UpdatedInventory.connect(refresh)
	refresh()

func refresh() -> void:
	button.disabled = !inventory.can_craft(recipe)
	
	var lines : PackedStringArray = []
	for ingredient in recipe.ingredients:
		var needed : int = recipe.ingredients[ingredient]
		var have : int = inventory.get_item_count(ingredient)
		var color := "white" if have >= needed else "#ff6666"
		lines.append("[color=%s]%s %d/%d[/color]" % [color, ingredient.item_id, have, needed])
	ingredients_label.text = "\n".join(lines)
