extends Node
class_name PlayerMovement

@onready var player = get_parent()
@onready var sprite = $"../Visual/Knight"
@onready var state = $"../PlayerState"
@onready var wall_check = $"../WallCheck"
@onready var floor_check = $"../FloorCheck"
@onready var spike_check = $"../SpikeCheck"

var tile_size = 32
var is_moving = false
var is_jumping = false
var is_falling = false

@export var jump_height := 2
@export var jump_distance := 2
@export var jump_duration := 0.45

func move_along_path(path: Array, duration := 0.4):

	if is_moving:
		return false

	if path.is_empty():
		return false

	is_moving = true

	var tween = create_tween()
	var segment_duration = duration / path.size()

	for point in path:
		tween.tween_property(
			player,
			"position",
			point,
			segment_duration
		)

	await tween.finished

	is_moving = false
	return true

func jump_to(offset_x: int):

	var start = player.position
	var end = start + Vector2(tile_size * offset_x, 0)

	is_jumping = true
	player.set_state_jump()
	AudioManager.play_sfx("jump")

	var tween = create_tween()

	tween.set_parallel()

	tween.tween_property(
		player,
		"position:x",
		end.x,
		jump_duration
	).set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(
		player,
		"position:y",
		start.y - tile_size * jump_height,
		jump_duration * 0.45
	).set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(
		player,
		"position:y",
		end.y,
		jump_duration * 0.55
	).set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_IN)

	await tween.finished

	is_jumping = false

	return true

func blocked(offset: Vector2):
	wall_check.target_position = offset
	wall_check.force_raycast_update()
	return wall_check.is_colliding()

func move_right():

	if player.is_dead or is_moving:
		return false

	sprite.flip_h = false

	if blocked(Vector2(tile_size,0)):
		return false

	state.change_state(PlayerState.State.RUN)

	var next = player.position + Vector2(tile_size,0)

	player.last_safe_position = player.position

	await move_along_path([next],0.18)

	return true

func move_left():

	if player.is_dead or is_moving:
		return false

	sprite.flip_h = true

	if blocked(Vector2(-tile_size,0)):
		return false

	state.change_state(PlayerState.State.RUN)

	var next = player.position + Vector2(-tile_size,0)

	player.last_safe_position = player.position

	await move_along_path([next],0.18)

	return true

func move_down():

	if player.is_dead or is_moving:
		return false

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	if floor_check.is_colliding():
		return false

	is_falling = true
	player.set_state_fall()

	var next = player.position + Vector2(0, tile_size)

	player.last_safe_position = player.position

	await move_along_path([next], 0.12)

	is_falling = false

	return true

func jump_right():

	if player.is_dead or is_moving:
		return false

	sprite.flip_h = false

	if blocked(Vector2(tile_size, -tile_size)):
		return false

	player.last_safe_position = player.position

	return await jump_to(jump_distance)

func jump_left():

	if player.is_dead or is_moving:
		return false

	sprite.flip_h = true

	if blocked(Vector2(-tile_size, -tile_size)):
		return false

	player.last_safe_position = player.position

	return await jump_to(-jump_distance)

func jump_up():

	if player.is_dead or is_moving:
		return false

	var next = player.position + Vector2(0, -tile_size * 2)

	if blocked(Vector2(0, -tile_size)):
		return false

	is_jumping = true
	player.set_state_jump()
	AudioManager.play_sfx("jump")

	player.last_safe_position = player.position

	await move_along_path([next], 0.25)

	is_jumping = false
	return true

func should_fall() -> bool:

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	return !floor_check.is_colliding()

func wall_on_right() -> bool:

	wall_check.target_position = Vector2(tile_size, 0)
	wall_check.force_raycast_update()

	return wall_check.is_colliding()

func wall_on_left() -> bool:

	wall_check.target_position = Vector2(-tile_size, 0)
	wall_check.force_raycast_update()

	return wall_check.is_colliding()

func spike_ahead() -> bool:

	if sprite.flip_h:
		spike_check.target_position = Vector2(-tile_size, 0)
	else:
		spike_check.target_position = Vector2(tile_size, 0)

	spike_check.force_raycast_update()

	return spike_check.is_colliding()
