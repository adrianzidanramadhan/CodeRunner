extends Node

class_name PlayerState

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	HIT,
	DEAD
}

var current_state = State.IDLE

@onready var sprite : AnimatedSprite2D = $"../Visual/Knight"

func change_state(new_state):

	if current_state == new_state:
		return

	current_state = new_state

	match current_state:

		State.IDLE:
			sprite.play("idle")

		State.RUN:
			sprite.play("run")

		State.JUMP:
			sprite.play("jump")

		State.FALL:
			sprite.play("fall")

		State.ATTACK:
			sprite.play("attack")

		State.HIT:
			sprite.play("hit")

		State.DEAD:
			sprite.play("death")
