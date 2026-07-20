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

@onready var sprite: AnimatedSprite2D = $"../Visual/Knight"

func is_busy() -> bool:
	return current_state in [
		State.ATTACK,
		State.HIT,
		State.DEAD
	]

func is_dead() -> bool:
	return current_state == State.DEAD


func change_state(new_state: State):

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

		State.HIT:
			sprite.play("hit")

		State.DEAD:
			sprite.play("death")
			
	play_state_audio()

func play_attack(combo: int):

	current_state = State.ATTACK

	match combo:

		1:
			sprite.play("attack")

		2:
			sprite.play("attack2")

func play_state_audio():

	match current_state:

		State.RUN:
			AudioManager.play_footsteps()

		_:
			AudioManager.stop_footsteps()
