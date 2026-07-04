extends Enemy
class_name Goblin

func _ready():
	max_health = 3
	move_speed = 0.18
	aggro_range = 6
	attack_range = 1
	super._ready()

func chase_player(distance):
	var dir = 1 if distance > 0 else -1
	move_dir = dir

	for i in range(2):
		if obstacle_ahead(dir):
			break
		await move_direction(dir)
