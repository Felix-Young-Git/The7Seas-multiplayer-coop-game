#This component goes on the player and is an area where the hitbox for where the player swings a 
#tool is
class_name HitComponent
extends Area2D

@export var current_tool : DataTypes.Tools = DataTypes.Tools.None
@export var hit_damage : int = 1
