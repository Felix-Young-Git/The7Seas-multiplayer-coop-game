extends Node2D

#packed scenes
@export var player_scene : PackedScene
@export var enemy_scene : PackedScene

#Connection info
var peer = ENetMultiplayerPeer.new()
const IP_ADDRESS: String = "localhost" #PLACEHOLDER
const PORT: int = 42069

#references
@onready var hostButton = $UI/Buttons/Host
@onready var joinButton = $UI/Buttons/Join
@onready var spawnEnemyButton = $UI/Buttons/SpawnEnemy
@onready var hostIPLabel = $"UI/IPInfo/HostInfo/HostIP"


#connect buttons, spawnenemy only visible for host
func _ready() -> void:
	hostButton.pressed.connect(_on_host_pressed)
	joinButton.pressed.connect(_on_join_pressed)
	spawnEnemyButton.pressed.connect(_on_spawn_enemy_pressed)
	spawnEnemyButton.visible = false
	hostIPLabel.visible = false

#create host
func _on_host_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	spawnEnemyButton.visible = true
	hostIPLabel.visible = true
	_request_public_ip()
	_add_player()

#create client
func _on_join_pressed() -> void:
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer


#get and show host public ip
func _request_public_ip():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	http.request("https://api.ipify.org") # Standard public IP service

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var public_ip = body.get_string_from_utf8().strip_edges()
		print("Public IP: ", public_ip)
		hostIPLabel.text = "Your IP: " + public_ip
	else:
		print("Failed to get IP. Response code: ", response_code)
	


#create player
func _add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)


#Spawning enemies
func _on_spawn_enemy_pressed(id = 1) -> void:
	if multiplayer.is_server():
		var enemy = enemy_scene.instantiate()
		add_child(enemy, true)
