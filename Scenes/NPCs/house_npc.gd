extends Node2D

#@export var required_items := {"wood": 5, "stone": 10}  # whatever your items are
@export var required_items : Dictionary[ItemData, int]
var house_fixed := false

@export var broken_house_layer : TileMapLayer
@export var fixed_house_layer : TileMapLayer

func _ready() -> void:
	_apply_house_state()

#player enters/exits---------------------------
func _on_interact_area_body_entered(body: Node) -> void:
	if body.has_method("add_interactable"):
		body.add_interactable(self)

func _on_interact_area_body_exited(body: Node) -> void:
	if body.has_method("remove_interactable"):
		body.remove_interactable(self)
#-------------------------------------

#player interaction-----------------------------------------------
func interact(_player):
	request_interact.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func request_interact() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender == 0:#host called locally
		sender = multiplayer.get_unique_id() 
	
	if house_fixed:
		show_text.rpc(sender, "Hope you like it!")
		return
	
	var player := _get_player(sender)
	if player == null:
		return
	var inventory : Inventory = player.get_node("Inventory")
	
	if inventory.has_items(required_items):
		inventory.remove_items(required_items)
		set_house_fixed.rpc()
		show_text.rpc_id(sender, "It's all fixed!")
	else:
		show_text.rpc_id(sender, "I need 5 wood and 10 stone to fix the house")

@rpc("authority", "call_local", "reliable")
func set_house_fixed() -> void:
	house_fixed = true
	_apply_house_state()

func _apply_house_state() -> void:
	broken_house_layer.enabled = not house_fixed
	fixed_house_layer.enabled = house_fixed

# Runs on one peer: the one who interacted
@rpc("authority", "call_local", "reliable")
func show_text(text: String) -> void:
	$"NPC text".text = text

func _get_player(peer_id: int) -> Node:
	for p in get_tree().get_nodes_in_group("players"):
		if p.get_multiplayer_authority() == peer_id:
			return p
	return null
#----------------------------------------------------------------
