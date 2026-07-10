extends Enemy
class_name Mushroom

func _ready():
	max_health = 2
	move_speed = 0.25
	aggro_range = 8
	attack_range = 1
	max_move_per_turn = 1
	super._ready()
