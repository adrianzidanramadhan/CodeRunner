extends CharacterBody2D

@export var speed = -50

func _physics_process(delta):
	velocity.x = speed
	move_and_slide()
