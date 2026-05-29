extends Control

@export var recipe_button_scene : PackedScene
@export var recipes : Array[CraftRecipe]

@onready var container = $Panel/ScrollContainer/VBoxContainer
@onready var inventory : Inventory = get_parent().get_parent().get_node("%Inventory")
@onready var player : Player = get_parent().get_parent()

func _ready():
	for recipe in recipes:
		var button = recipe_button_scene.instantiate()
		container.add_child(button)
		button.set_recipe(recipe, inventory)
		
		button.pressed.connect(craft_recipe.bind(recipe))


func craft_recipe(recipe : CraftRecipe):
	print("1")
	player.send_craft_request(recipe.recipe_id)
