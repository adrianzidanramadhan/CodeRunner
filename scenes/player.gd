extends CharacterBody2D

var tile_size = 32

var is_moving = false
var is_jumping = false
var is_falling = false
var is_dead = false
var is_attacking = false
var start_position = Vector2()
var hit_targets = []
var sword_offset_right = Vector2(0, 0)
var sword_offset_left = Vector2(-75, 0)
var last_safe_position : Vector2
var is_taking_hit := false

var path = [
	position + Vector2(tile_size * 0.5, -tile_size * jump_height),
	position + Vector2(tile_size * 1.5, -tile_size * jump_height),
	position + Vector2(tile_size * jump_distance, 0)
]

@onready var spike_check = $SpikeCheck
@onready var wall_check = $WallCheck
@onready var floor_check = $FloorCheck
@onready var sprite = $Visual/Knight
@onready var state = $PlayerState

@export var jump_height := 2
@export var jump_distance := 2
@export var jump_duration := 0.45

func _ready():
	add_to_group("player")
	start_position = position
	last_safe_position = position
	$SwordHitbox.monitoring = false
	set_state_idle()
	update_sword_hitbox()

# =====================================================
# STATE / ANIMATION
# =====================================================

func play_anim(anim_name):
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func set_state_idle():

	state.change_state(PlayerState.State.IDLE)

	AudioManager.stop_footsteps()


func set_state_run():

	state.change_state(PlayerState.State.RUN)

	AudioManager.play_footsteps()


func set_state_jump():

	state.change_state(PlayerState.State.JUMP)

	AudioManager.stop_footsteps()


func set_state_fall():

	state.change_state(PlayerState.State.FALL)

	AudioManager.stop_footsteps()


func set_state_death():

	state.change_state(PlayerState.State.DEAD)

	AudioManager.stop_footsteps()


func stop_action():

	if is_dead:
		return

	if is_taking_hit:
		return

	is_moving = false
	is_jumping = false
	is_falling = false

	set_state_idle()

# =====================================================
# CORE MOVEMENT
# =====================================================

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
			self,
			"position",
			point,
			segment_duration
		)

	await tween.finished

	is_moving = false
	return true

func jump_to(offset_x: int):

	var start = position
	var end = start + Vector2(tile_size * offset_x, 0)

	is_jumping = true
	set_state_jump()
	AudioManager.play_sfx("jump")

	var tween = create_tween()

	tween.set_parallel()

	tween.tween_property(
		self,
		"position:x",
		end.x,
		jump_duration
	).set_trans(Tween.TRANS_LINEAR)

	tween.tween_property(
		self,
		"position:y",
		start.y - tile_size * jump_height,
		jump_duration * 0.45
	).set_trans(Tween.TRANS_QUAD)\
	.set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(
		self,
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


# =====================================================
# WALK
# =====================================================

func move_right():

	if is_dead or is_moving or is_attacking:
		return false

	sprite.flip_h = false
	update_sword_hitbox()

	if blocked(Vector2(tile_size, 0)):
		return false

	set_state_run()

	var next = position + Vector2(tile_size, 0)

	last_safe_position = position

	await move_along_path([next], 0.18)

	return true


func move_left():

	if is_dead or is_moving or is_attacking:
		return false

	sprite.flip_h = true
	update_sword_hitbox()

	if blocked(Vector2(-tile_size, 0)):
		return false

	set_state_run()

	var next = position + Vector2(-tile_size, 0)

	last_safe_position = position

	await move_along_path([next], 0.18)

	return true


# =====================================================
# FALL
# =====================================================

func move_down():

	if is_dead or is_moving or is_attacking:
		return false

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	if floor_check.is_colliding():
		return false

	is_falling = true
	set_state_fall()

	var next = position + Vector2(0, tile_size)

	last_safe_position = position

	await move_along_path([next], 0.12)

	is_falling = false

	return true


func should_fall():
	print(global_position.y)
	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	return !floor_check.is_colliding()

# =====================================================
# JUMP
# =====================================================
func jump_right():

	if is_dead or is_moving or is_attacking:
		return false

	sprite.flip_h = false
	update_sword_hitbox()

	if blocked(Vector2(tile_size, -tile_size)):
		return false

	last_safe_position = position

	return await jump_to(jump_distance)


func jump_left():

	if is_dead or is_moving or is_attacking:
		return false

	sprite.flip_h = true
	update_sword_hitbox()

	if blocked(Vector2(-tile_size, -tile_size)):
		return false

	last_safe_position = position

	return await jump_to(-jump_distance)

func jump_up():

	if is_dead or is_moving or is_attacking:
		return false

	var next = position + Vector2(0, -tile_size * 2)

	if blocked(Vector2(0, -tile_size)):
		return false

	is_jumping = true
	set_state_jump()
	AudioManager.play_sfx("jump")

	last_safe_position = position

	await move_along_path([next], 0.25)

	is_jumping = false
	return true


# =====================================================
# RESET / DEATH
# =====================================================

func reset_player():

	position = start_position

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

	AudioManager.play_sfx("death")
	set_state_death()

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# =====================================================
# DETECTION
# =====================================================

func wall_on_right():

	wall_check.target_position = Vector2(tile_size, 0)
	wall_check.force_raycast_update()
	return wall_check.is_colliding()
	
func wall_on_left() -> bool:
	wall_check.target_position = Vector2(-tile_size, 0) # Mengecek 	ke arah kiri
	wall_check.force_raycast_update()
	return wall_check.is_colliding()

func spike_ahead():

	if sprite.flip_h:
		spike_check.target_position = Vector2(-tile_size, 0)
	else:
		spike_check.target_position = Vector2(tile_size, 0)

	spike_check.force_raycast_update()

	return spike_check.is_colliding()

func attack(direction := "front"):
	if is_attacking:
		return false

	is_attacking = true
	
	if direction == "left":
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	update_sword_hitbox()

	sprite.play("attack")
	AudioManager.play_sfx("attack")
	
	await get_tree().create_timer(0.08).timeout
	
	hit_targets.clear()
	$SwordHitbox.monitoring = true
	await get_tree().create_timer(0.06).timeout
	$SwordHitbox.monitoring = false

	await sprite.animation_finished

	await get_tree().create_timer(0.25).timeout

	sprite.play("attack2")
	AudioManager.play_sfx("attack")
	
	hit_targets.clear()
	$SwordHitbox.monitoring = true
	await get_tree().create_timer(0.15).timeout
	$SwordHitbox.monitoring = false

	await sprite.animation_finished

	is_attacking = false
	set_state_idle()
	
	return true

func update_sword_hitbox():
	if sprite.flip_h:
		$SwordHitbox.position = sword_offset_left
	else:
		$SwordHitbox.position = sword_offset_right

func hit_stop(duration := 0.06, scale := 0.05):
	Engine.time_scale = scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1

func _on_sword_hitbox_body_entered(body):
	if body in hit_targets:
		return

	hit_targets.append(body)
	
	var attack_dir = 1
	if sprite.flip_h:
		attack_dir = -1

	#print("hit:", body.name)

	if body.has_method("take_damage"):
		await body.take_damage(1, attack_dir)

func take_hit():

	if is_dead:
		return

	is_taking_hit = true
	is_moving = true

	sprite.play("hit")

	AudioManager.play_sfx("hit")

	var tween = create_tween()

	tween.tween_property(
		self,
		"position",
		last_safe_position,
		0.12
	).set_trans(Tween.TRANS_BACK)\
	.set_ease(Tween.EASE_OUT)

	await tween.finished

	is_moving = false
	is_taking_hit = false

	set_state_idle()
