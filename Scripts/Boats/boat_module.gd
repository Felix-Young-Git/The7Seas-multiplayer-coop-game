#base class that all upgrades to the boad extend
extends Resource
class_name BoatModule

var module_id = ""

func modify_speed(current_speed: float, boat: Boat) -> float:
	return current_speed  # no change by default

func modify_collision_damage(current_damage: float, collision_info, boat: Boat) -> float:
	return current_damage

func on_enter_ocean(ocean_type: String, boat: Boat) -> void:
	pass

#This is going to be an issue if I have multipe upgrades calling this
func modify_boat_visuals(boat: Boat):
	pass
