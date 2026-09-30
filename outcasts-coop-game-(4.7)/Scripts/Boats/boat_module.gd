#base class that all upgrades to the boad extend
extends Resource
class_name BoatModule

var module_id : String = ""

func modify_speed(current_speed: float, boat: Boat) -> float:
	return current_speed  # no change by default

func modify_collision(boat: Boat):
	pass

func on_enter_ocean(ocean_type: String, boat: Boat) -> void:
	pass

#This is going to be an issue if I have multipe upgrades calling this
func modify_boat_visuals(boat: Boat):
	pass
