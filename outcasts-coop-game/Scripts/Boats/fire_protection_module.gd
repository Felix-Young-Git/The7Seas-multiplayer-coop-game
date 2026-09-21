extends BoatModule
class_name FireProtectionModule

func _init() -> void:
	module_id = "heat_protection_module"

func modify_collision(boat: Boat):
	boat.set_collision_mask_value(9, false)
	
func modify_boat_visuals(boat: Boat):
	boat.modulate = Color(1.0, 0.0, 0.0, 1.0)
