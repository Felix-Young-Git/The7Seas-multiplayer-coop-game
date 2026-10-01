extends CanvasLayer

signal host_pressed
signal join_pressed
signal spawn_enemy_pressed

@onready var host_button = $LoginVBox/Buttons/Host
@onready var join_button = $LoginVBox/Buttons/Join
@onready var spawn_enemy_button = $LoginVBox/Buttons/SpawnEnemy
@onready var hostLobbyCode = $LoginVBox/IPInfo/HostLobbyCode
@onready var joinLobbyCode = $LoginVBox/IPInfo/JoinLobbyCode

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	spawn_enemy_button.pressed.connect(_on_spawn_enemy_button_pressed)

func _on_host_button_pressed():
	host_pressed.emit()

func _on_join_button_pressed():
	join_pressed.emit()

func _on_spawn_enemy_button_pressed():
	spawn_enemy_pressed.emit()

func get_host_IP_input() -> String:
	return hostLobbyCode.text

func get_join_IP_input() -> String:
	return joinLobbyCode.text

#ui states
enum UIState {
	Menu,
	Host,
	Join
}

func set_state(state: UIState):
	match state:
		UIState.Menu:
			host_button.visible = true
			join_button.visible = true
			spawn_enemy_button.visible = false
			#host ip lable is not visible but still there so the join ip input is in the right place
			#hostLobbyCode.modulate.a = 0.0
			joinLobbyCode.visible = true

		UIState.Host:
			host_button.visible = false
			join_button.visible = false
			spawn_enemy_button.visible = false
			hostLobbyCode.modulate.a = 0.0
			joinLobbyCode.visible = false

		UIState.Join:
			host_button.visible = false
			join_button.visible = false
			spawn_enemy_button.visible = false
			hostLobbyCode.modulate.a = 0.0
			joinLobbyCode.visible = false
