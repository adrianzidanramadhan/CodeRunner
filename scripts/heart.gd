extends Control

@onready var sprite = $AnimatedSprite2D

func set_full():
	sprite.play("idle")

func set_empty():
	sprite.play("empty")

func play_damage():
	sprite.play("damage")

func play_heal():
	sprite.play("heal")
