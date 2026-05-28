class_name CraftRecipe
extends Resource



@export var ingredients : Dictionary[ItemData, int]
@export var required_stations : Array[String]

@export var output_item: ItemData
@export var output_amount: int = 1
