#This goes on an item that should be able to be picked up by the player
class_name CollectableComponent
extends Area2D

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

#I think this is running 2x which will be a problem-------------
func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	
	if is_collected:
		return
	
	print("body entered")
	if body is Player:
		print("Collected by", body.name)
		
		# Give the item to the player inventory logic here
		# body.inventory.add_item(collectable_name)
		
		#the collectable component will be attached to another node so that node will be removed
		get_parent().queue_free()
