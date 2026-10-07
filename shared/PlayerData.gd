class_name PlayerData
extends RefCounted
##Player data object
##
##Contains necessary data for the player entity to work

##Constant movement speed
const player_movement_speed: float = 1.0
const npc_movement_speed: float = 0.5

##Position of player
var position: Vector2

##Previous position of player
var previous_position: Vector2

##Current position change of player, starts with no direction
var movement_direction:= Vector2.ZERO

##If player recently changed direction
var change_of_direction: bool = false

##If player's movement must be reported, wether for a change in movement direction or constant movement
var recent_movement: bool = false

##If player has requested and succesfully loaded into world
var world_loaded: bool = false

func _init(
	player_position: Vector2
):
	position = player_position
