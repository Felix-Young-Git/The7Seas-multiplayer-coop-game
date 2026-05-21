#This goes on an object that can take damage and signals when the object has taken its max damage
class_name DamageComponent
extends Node2D

@export var max_damage = 3
@export var current_damage = 0


func apply_damage(damage: int) -> void:
	#if current_damage + damage > max_damage then current_damage = max_damage,
	#otherwise current_damage = current_damage + damage
	current_damage = clamp(current_damage + damage, 0, max_damage)
	

func is_dead() -> bool:
	if current_damage >= max_damage:
		return true
	else:
		return false
