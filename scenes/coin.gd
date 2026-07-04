extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" or body.has_method("move_down"):
		var current_level = get_tree().current_scene
		if current_level and current_level.has_method("collect_coin"):
			current_level.collect_coin()
		queue_free()
