extends Area2D
class_name Spike

@export var damage := 1
@export var instant_kill := true
@export var active := true

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if !active:
		return

	if triggered:
		return

	if body is CharacterBody2D:
		triggered = true
		await on_hit(body)

func on_hit(body):
	if body.has_method("die"):
		await body.die()
		LevelManager.reload_level()
