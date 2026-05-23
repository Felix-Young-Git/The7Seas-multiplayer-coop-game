#This goes on an item that should be able to be picked up by the player
class_name CollectableComponent
extends Area2D

@export var small_log : ResourseItemData
@export var small_rock : ResourseItemData

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if is_collected:
		return
	
	if body is Player:
		print("Collected by ", body.name)
		
		#need to use the body's name to give the item to the right player
		#in order to fix this
		if get_parent().name.contains("small_rock"):
			print("collecting rock")
			body.inventory.add_item(small_rock)
		
		if get_parent().name.contains("small_log"):
			print("collecting log")
			body.inventory.add_item(small_log)
		
		#the collectable component will be attached to another node so that node will be removed
		get_parent().queue_free()
