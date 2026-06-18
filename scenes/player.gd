#player.gd
extends CharacterBody2D

var tile_size = 32
var is_moving = false
var is_jumping = false
var is_falling = false
var is_dead = false
var is_arc_jumping = false

var target_position = Vector2()
var start_position = Vector2()

@onready var spike_check = $SpikeCheck
@onready var wall_check = $WallCheck
@onready var floor_check = $FloorCheck
@onready var sprite = $Visual/Knight

func _ready():

	target_position = position
	start_position = position

	set_state_idle()

func _process(delta):

	if is_moving and !is_arc_jumping:

		position = position.move_toward(
			target_position,
			200 * delta
		)

		if position.distance_to(target_position) < 1:

			position = target_position
			is_moving = false

			if is_jumping:
				is_jumping = false

			if is_falling:
				is_falling = false


func stop_action():

	if is_dead:return

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_idle()


func play_anim(anim_name):

	if sprite.animation != anim_name:
		sprite.play(anim_name)

func set_state_idle():
	play_anim("idle")
	AudioManager.stop_footsteps()

func set_state_run():
	play_anim("run")
	AudioManager.play_footsteps()

func set_state_jump():
	play_anim("jump")
	AudioManager.stop_footsteps()

func set_state_fall():
	play_anim("fall")
	AudioManager.stop_footsteps()

func set_state_death():
	play_anim("death")
	AudioManager.stop_footsteps()
	

func move_right():

	sprite.flip_h = false

	if is_dead:
		return false

	if is_moving:
		return false

	wall_check.target_position = Vector2(tile_size, 0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():

		print("Tembok di kanan!")
		return false

	target_position += Vector2(tile_size, 0)

	is_moving = true

	set_state_run()

	return true


func move_left():

	sprite.flip_h = true

	if is_dead:
		return false

	if is_moving:
		return false

	wall_check.target_position = Vector2(-tile_size, 0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():

		print("Tembok di kiri!")
		return false

	target_position += Vector2(-tile_size, 0)

	is_moving = true

	set_state_run()

	return true


func move_up():

	if is_dead:
		return false

	if is_moving:
		return false

	wall_check.target_position = Vector2(0, -tile_size)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():

		print("Tembok di atas!")
		return false

	is_jumping = true
	is_moving = true

	target_position += Vector2(0, -tile_size)

	set_state_jump()

	return true


func jump_arc(direction):

	if is_moving:
		return false

	is_arc_jumping = true
	is_jumping = true

	AudioManager.play_sfx("jump")
	set_state_jump()

	var end = position + Vector2(
		direction.x * tile_size * 2,
		0
	)
	
	target_position = end

	wall_check.target_position = Vector2(
		direction.x * tile_size * 2,
		0
	)

	wall_check.force_raycast_update()

	if wall_check.is_colliding():
		target_position = position
		is_arc_jumping = false
		is_jumping = false
		set_state_idle()
		return false

	# Horizontal
	var move_tween = create_tween()

	move_tween.tween_property(
		self,
		"position",
		end,
		0.5
	)

	# Arc visual
	var visual_tween = create_tween()

	visual_tween.set_trans(Tween.TRANS_SINE)

	# Naik
	visual_tween.tween_property(
		$Visual,
		"position:y",
		-90,
		0.20
	)

	# Ganti animasi jadi fall di puncak
	visual_tween.tween_callback(
		func():
			set_state_fall()
	)

	# Turun sedikit lebih lama
	visual_tween.tween_property(
		$Visual,
		"position:y",
		-30,
		0.30
	)

	await move_tween.finished

	is_arc_jumping = false
	is_jumping = false

	set_state_idle()

	return true


func is_airborne():
	return is_arc_jumping or is_jumping


func should_fall():

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	return !floor_check.is_colliding()


func reset_player():

	position = start_position
	target_position = start_position

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_idle()

func die():

	if is_dead:
		return
	
	is_dead = true

	is_moving = false
	is_jumping = false
	is_falling = false

	target_position = position

	set_state_death()

	await get_tree().create_timer(2.0).timeout


func wall_on_right():

	wall_check.target_position = Vector2(tile_size, 0)

	wall_check.force_raycast_update()

	return wall_check.is_colliding()


func spike_ahead():

	if sprite.flip_h:

		spike_check.target_position = Vector2(-tile_size, 0)
	else:
		spike_check.target_position = Vector2(tile_size, 0)

	spike_check.force_raycast_update()

	return spike_check.is_colliding()
