extends Node2D

@onready var emblem = $AnimatedSprite2D

var is_playing := false

func _ready():
	emblem.play("idle")

func shine():

	if is_playing:
		return

	is_playing = true

	emblem.play("shine")

	await emblem.animation_finished

	emblem.play("idle")

	is_playing = false
