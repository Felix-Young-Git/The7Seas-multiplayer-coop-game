#This goes on an item that should be able to be picked up by the player
class_name CollectableComponent
extends Area2D

@export var collectable_name: String


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		print("Collected")
		#the collectable component will be attached to another node so that node will be removed
		get_parent().queue_free()
