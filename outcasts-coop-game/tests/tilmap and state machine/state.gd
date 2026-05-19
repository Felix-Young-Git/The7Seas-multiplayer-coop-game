class_name NodeState
extends Node

@warning_ignore("unused_signal")
signal transition 

#run stuff
func _on_process(_delta : float) -> void:
	pass

#run stuff
func _on_physics_process(_delta : float) -> void:
	pass

#transition to diff state
func _on_next_transitions() -> void:
	pass

#run when enter
func _on_enter() -> void:
	pass

#run when exit
func _on_exit() -> void:
	pass
