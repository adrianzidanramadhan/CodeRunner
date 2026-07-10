extends Enemy
class_name Goblin

func _ready():
	max_health = 3
	move_speed = 0.18
	aggro_range = 10
	attack_range = 1
	max_move_per_turn = 2

	super._ready()
