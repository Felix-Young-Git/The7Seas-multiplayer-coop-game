class_name CollectableComponent
extends Area2D

@export var item : ResourseItemData

var is_collected : bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not multiplayer.is_server():
		return
	if is_collected or item == null:
		return
	if body is Player:
		# only collect if the player actually had room
		if not body.inventory.add_item(item):
			return
		is_collected = true
		_remove_collectable()

func _remove_collectable() -> void:
	var node := get_parent()
	var layer := node.get_parent()
	if layer is TileMapLayer:
		# placed in a tilemap: the cell has to be erased on every peer
		var cell : Vector2i = layer.local_to_map(layer.to_local(node.global_position))
		var tilemap = get_tree().get_first_node_in_group("tilemap")
		tilemap.remove_tile_everywhere.call_deferred(layer.name, cell)
	else:
		# spawned at runtime (your dropped logs/rocks/berries)
		node.queue_free()
