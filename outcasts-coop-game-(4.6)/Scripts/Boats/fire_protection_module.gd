extends BoatModule
class_name FireProtectionModule

func modify_collision_damage(current_damage: float, collision_info, boat: Boat) -> float:
	if collision_info == "lava":
		return 0.0  # no damage from lava ocean collision
	return current_damage
	
func modify_boat_visuals(boat: Boat):
	boat.modulate = Color(1.0, 0.0, 0.0, 1.0)
