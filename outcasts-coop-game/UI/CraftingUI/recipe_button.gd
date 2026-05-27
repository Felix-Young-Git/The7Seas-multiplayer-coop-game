class_name RecipeButton
extends Button


var recipe : CraftRecipe

func set_recipe(new_recipe : CraftRecipe):
	recipe = new_recipe
	text = recipe.output_item.display_name
	icon = recipe.output_item.icon
