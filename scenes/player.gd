extends CharacterBody2D

var is_dead = false
var is_attacking = false
var start_position = Vector2()
var last_safe_position : Vector2
var is_taking_hit := false

@onready var spike_check = $SpikeCheck
@onready var wall_check = $WallCheck
@onready var floor_check = $FloorCheck
@onready var sprite = $Visual/Knight
@onready var state = $PlayerState
@onready var combat = $PlayerCombat
@onready var movement = $PlayerMovement
@onready var health = $PlayerHealth


func _ready():
	add_to_group("player")
	start_position = position
	last_safe_position = position
	$SwordHitbox.monitoring = false
	set_state_idle()

func set_state_idle():

	state.change_state(PlayerState.State.IDLE)

func set_state_run():

	state.change_state(PlayerState.State.RUN)

func set_state_jump():

	state.change_state(PlayerState.State.JUMP)

func set_state_fall():

	state.change_state(PlayerState.State.FALL)

func set_state_death():

	state.change_state(PlayerState.State.DEAD)

func stop_action():

	if is_dead:
		return

	if state.is_busy():
		return

	set_state_idle()

func move_right():
	return await movement.move_right()

func move_left():
	return await movement.move_left()

func move_down():
	return await movement.move_down()

func jump_right():
	return await movement.jump_right()

func jump_left():
	return await movement.jump_left()

func jump_up():
	return await movement.jump_up()

func attack(direction := "front"):

	return await combat.attack(direction)

func hit_stop(duration := 0.06, scale := 0.05):
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1

func take_hit():
	return await health.take_hit()

func die():
	return await health.die()

func reset_player():
	health.reset()

func should_fall():
	return movement.should_fall()
