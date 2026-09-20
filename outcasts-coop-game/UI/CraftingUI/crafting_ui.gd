extends Control

@export var recipe_button_scene : PackedScene
@export var recipes : Array[CraftRecipe]
@export var upgrades : Array[UpgradeRecipe]

@onready var container = $Panel/ScrollContainer/VBoxContainer
@onready var inventory : Inventory = get_parent().get_parent().get_node("%Inventory")
@onready var player : Player = get_parent().get_parent()

func _ready():
	for recipe in recipes:
		var button = recipe_button_scene.instantiate()
		container.add_child(button)
		button.set_recipe(recipe, inventory)
		
		button.pressed.connect(craft_recipe.bind(recipe))
	
	for upgrade in upgrades:
		var button = recipe_button_scene.instantiate()
		container.add_child(button)
		button.set_recipe(upgrade, inventory)
		
		button.pressed.connect(craft_upgrade.bind(upgrade))

func craft_upgrade(recipe : UpgradeRecipe):
	player.send_craft_request(recipe.recipe_id)

func craft_recipe(recipe : CraftRecipe):
	player.send_craft_request(recipe.recipe_id)
