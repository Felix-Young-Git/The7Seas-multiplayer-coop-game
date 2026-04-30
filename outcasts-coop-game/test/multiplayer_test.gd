extends Node2D


@export var player_scene : PackedScene
@export var enemy_scene : PackedScene

#Connection info
var peer = ENetMultiplayerPeer.new()
const IP_ADDRESS: String = "localhost"
const PORT: int = 42069


#connect buttons
func _enter_tree() -> void:
	$UI/Host.pressed.connect(_on_host_pressed)
	$UI/Join.pressed.connect(_on_join_pressed)
	$UI/SpawnEnemy.pressed.connect(_on_spawn_enemy_pressed)

#create host
func _on_host_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()

#create client
func _on_join_pressed() -> void:
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer

func _on_spawn_enemy_pressed(id = 1) -> void:
	var enemy = enemy_scene.instantiate()
	enemy.name = str(id)
	call_deferred("add_child", enemy)

#create player
func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
