extends Node2D

#packed scenes
@export var player_scene : PackedScene
@export var enemy_scene : PackedScene

#Connection info
var peer = ENetMultiplayerPeer.new()
var IP_ADDRESS: String = "" 
const PORT: int = 42069

@onready var ui = $UI

#connect buttons, spawnenemy only visible for host
func _ready() -> void:
	#connect the buttons
	$UI.host_pressed.connect(_on_host_pressed)
	$UI.join_pressed.connect(_on_join_pressed)
	$UI.spawn_enemy_pressed.connect(_on_spawn_enemy_pressed)
	
	#set ui state
	ui.set_state(ui.UIState.Menu)
	
	#Server connection info
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
	multiplayer.peer_connected.connect(_peer_connected)


#create host
func _on_host_pressed() -> void:
	#New Error handling 
	var error = peer.create_server(PORT)
	if error != OK:
		print("Failed to create server: ", error)
		return
	print("SERVER CREATE RESULT: ", error)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_add_player) #whenever a new peer connects to the host the host runs add_player
	
	#set ui state
	ui.set_state(ui.UIState.Host)
	
	#spawn the host
	_add_player(multiplayer.get_unique_id())
	

#create client
func _on_join_pressed() -> void:
	#GET IP ADDRESS from join port input, if no input then return
	var joinIPInput = ui.get_join_IP_input()
	if joinIPInput == "":
		print("Input IP Address")
		return
	IP_ADDRESS = joinIPInput
	
	#New Error handling
	var error = peer.create_client(IP_ADDRESS, PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return
	print("CLIENT CREATE RESULT: ", error)
	multiplayer.multiplayer_peer = peer

	#set ui state
	ui.set_state(ui.UIState.Join)

#create player
func _add_player(id: int):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)


#Spawning enemies
func _on_spawn_enemy_pressed(id = 1) -> void:
	if multiplayer.is_server():
		var enemy = enemy_scene.instantiate()
		add_child(enemy, true)


#server connection func
func _connected_ok():
	print("Connected to server!")

func _connected_fail():
	print("Failed to connect!")

func _peer_connected(id):
	print("Peer connected: ", id)

func _server_disconnected():
	print("Disconnected from server!")
