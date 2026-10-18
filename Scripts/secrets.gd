extends Node

var _cfg := ConfigFile.new()
var _loaded := false

func get_secret(section: String, key: String) -> String:
	if not _loaded:
		_loaded = true
		if _cfg.load("res://secrets.cfg") != OK:
			push_error("secrets.cfg not found. Copy secrets.example.cfg to secrets.cfg and fill in your values.")
	return str(_cfg.get_value(section, key, ""))
