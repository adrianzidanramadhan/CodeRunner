extends Node
class_name PlayerHealth

@onready var player = get_parent()
@onready var state = $"../PlayerState"

var max_hp := 3
var hp := max_hp

var invincible := false

func take_hit():

	if state.is_dead():
		return

	if invincible:
		return

	invincible = true

	state.change_state(PlayerState.State.HIT)

	AudioManager.play_sfx("hit")

	var tween = create_tween()

	tween.tween_property(
		player,
		"position",
		player.last_safe_position,
		0.12
	).set_trans(Tween.TRANS_BACK)\
	.set_ease(Tween.EASE_OUT)

	await tween.finished

	state.change_state(PlayerState.State.IDLE)

	await get_tree().create_timer(0.25).timeout

	invincible = false

func damage(amount := 1):

	hp -= amount

	if hp <= 0:
		die()
	else:
		await take_hit()

func die():

	if state.is_dead():
		return

	state.change_state(PlayerState.State.DEAD)

	player.is_dead = true

	AudioManager.play_sfx("death")

	await get_tree().create_timer(2).timeout

	get_tree().reload_current_scene()

func reset():

	hp = max_hp

	player.position = player.start_position

	player.is_dead = false

	state.change_state(PlayerState.State.IDLE)
