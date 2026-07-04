extends Enemy
class_name Mushroom

func _ready():
	max_health = 2
	move_speed = 0.25
	aggro_range = 4
	attack_range = 1
	super._ready()
