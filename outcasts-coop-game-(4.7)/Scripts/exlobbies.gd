extends Control

signal logged_in()
signal player_connected(player_id)
signal player_disconnected(player_id)

@onready var peer: EOSGMultiplayerPeer = EOSGMultiplayerPeer.new()

var local_user_id = ""
var is_server = false
var peer_user_ids = []

var EosSetup = false

var local_lobby: HLobby

func _ready() -> void:
	#Initialize the SDK
	if not EosSetup:
		var init_opts = EOS.Platform.InitializeOptions.new()
		init_opts.product_name = "No Opinion" #Replace EosCredentials.PRODUCT_NAME with your actual PRODUCT_NAME from the EOS website
		init_opts.product_version = "6d54e05ec6fa49a7babe165fe52f7a47" #Replace EosCredentials.PRODUCT_ID with your actual PRODUCT_ID from the EOS website
	
		var init_results = EOS.Platform.PlatformInterface.initialize(init_opts)
		if init_results != EOS.Result.Success:
			printerr("Failed to initialize EOS SDK: " + EOS.result_str(init_results))
			return
	
		# Create EOS platform
		var create_opts = EOS.Platform.CreateOptions.new()
		create_opts.product_id = "6d54e05ec6fa49a7babe165fe52f7a47" #Replace EosCredentials.PRODUCT_ID with your actual PRODUCT_ID from the EOS website
		create_opts.sandbox_id = "ca88589607ac4ab49b0f6a5146683a0a" #Replace EosCredentials.SANDBOX_ID with your actual SANDBOX_ID from the EOS website
		create_opts.deployment_id = "44b75217082c4784a998e578be4429a0" #Replace EosCredentials.DEPLOYMENT_ID with your actual DEPLOYMENT_ID from the EOS website
		create_opts.client_id = "xyza7891Ejiu5CK5cx9iOTYLbkortUZF" #Replace EosCredentials.CLIENT_ID with your actual CLIENT_ID from the EOS website
		create_opts.client_secret = "GSDeZqGWyMat0Wif1Q76A5WSUts1gfDgtHOjG2uQk5w" #Replace EosCredentials.CLIENT_SECRET with your actual CLIENT_SECRET from the EOS website
		create_opts.encryption_key = "7820596134872609537184269058371462905738164290537184629053718314" #Replace EosCredentials.ENCRYPTION_KEY with your any string of 64 numbers
	
		var _create_results = 0
		_create_results = EOS.Platform.PlatformInterface.create(create_opts)
	
		EOS.get_instance().connect_interface_login_callback.connect(_on_connect_login_callback)
	
		peer.peer_connected.connect(_on_peer_connected)
		peer.peer_disconnected.connect(_on_peer_disconnected)
		
		await HAuth.login_anonymous_async("User")
		EosSetup = true
		
		logged_in.emit()
	else:
		peer.peer_connected.connect(_on_peer_connected)
		peer.peer_disconnected.connect(_on_peer_disconnected)
		logged_in.emit()
	
func exit_game():
	if peer:
		peer.close()
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	if is_server and local_lobby:
		await local_lobby.destroy_async()
	elif local_lobby:
		await local_lobby.leave_async()
	
func _exit_tree() -> void:
	exit_game()

func _on_connect_login_callback(data: Dictionary) -> void:
	if not data.success:
		print("Login failed")
		EOS.print_result(data)
		return
		
	local_user_id = data.local_user_id
	HAuth.product_user_id = local_user_id
		
#LOBBY CREATION CODE
#-----------------------------------#
func create_lobby(lobby_id = null, max_players = 8):
	var create_opts := EOS.Lobby.CreateLobbyOptions.new()
	if lobby_id != null and lobby_id != "":
		create_opts.bucket_id = "No_Opinion_" + lobby_id
	else: 
		create_opts.bucket_id = "No_Opinion"
		
	create_opts.max_lobby_members = max_players

	var new_lobby = await HLobbies.create_lobby_async(create_opts)
	
	if new_lobby == null:
		return false
	
	# Start listening for P2P
	var result := peer.create_server("qmnoopinion")
	if result != OK:
		return false
		
	multiplayer.multiplayer_peer = peer
	is_server = true
	local_lobby = new_lobby
	return true

#LOBBY JOIN CODE
#---------------------------------------#
func search_lobbies(lobby_id = null) -> bool:
	# Search for public lobbies
	var lobbies
	if lobby_id != null and lobby_id != "":
		lobbies = await HLobbies.search_by_bucket_id_async("No_Opinion_" + lobby_id)
	else:
		lobbies = await HLobbies.search_by_bucket_id_async("No_Opinion")
		
	if not lobbies:
		return false

	# Join a lobby
	var lobby: HLobby = lobbies[0]
	await HLobbies.join_by_id_async(lobby.lobby_id)
	
	var result := peer.create_client("qmnoopinion", lobby.owner_product_user_id)
	if result != OK:
		return false
		
	multiplayer.multiplayer_peer = peer
	return true
	
func lock_lobby():
	if is_server and local_lobby:
		local_lobby.permission_level = EOS.Lobby.LobbyPermissionLevel.InviteOnly
		var success = await local_lobby.update_async()
		if success:
			print("Lobby locked (hidden from search)")
		else:
			print("Failed to lock lobby")
	
#GAME CODE
#-----------------------------------#
func _on_peer_connected(peer_id: int) -> void:
	peer_user_ids.append(peer_id)
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_user_ids.erase(peer_id)
	player_disconnected.emit(peer_id)
