extends Area2D
class_name Spike

signal touched

func _ready():
	add_to_group("spike")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if body.is_in_group("player"):
		touched.emit()
