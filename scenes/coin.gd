extends Area2D
class_name Coin

signal collected

var is_collected := false

func _ready():
	add_to_group("coin")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if is_collected:
		return

	if !body.is_in_group("player"):
		return

	is_collected = true

	collected.emit()

	AudioManager.play_sfx("coin")

	hide()
	$CollisionShape2D.set_deferred("disabled", true)

	queue_free()
