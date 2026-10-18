extends Node

var _cfg := ConfigFile.new()

func _ready() -> void:
	var err := _cfg.load("res://secrets.cfg")
	if err != OK:
		push_error("secrets.cfg not found. Copy secrets.example.cfg to secrets.cfg and fill in your values.")

func get_secret(section: String, key: String) -> String:
	return str(_cfg.get_value(section, key, ""))
