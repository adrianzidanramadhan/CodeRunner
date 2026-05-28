extends CharacterBody2D

var tile_size = 32
var is_moving = false
var target_position = Vector2()
var is_jumping = false

func _ready():
	target_position = position

func _process(delta):
	if is_moving:
		position = position.move_toward(target_position, 200 * delta)

		if position.distance_to(target_position) < 1:
			position = target_position
			is_moving = false

func move_right():
	
	sprite.flip_h = false

	if is_moving:
		return false

	wall_check.target_position = Vector2(tile_size, 0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():
		print("Tembok di kanan!")
		return false

	target_position += Vector2(tile_size, 0)
	is_moving = true

	return true


func move_left():

	sprite.flip_h = true

	if is_moving:
		return false

	wall_check.target_position = Vector2(-tile_size, 0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():
		print("Tembok di kiri!")
		return false

	target_position += Vector2(-tile_size, 0)
	is_moving = true

	return true


func move_up():

	if is_moving:
		return false

	wall_check.target_position = Vector2(0, -tile_size)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():
		print("Tembok di atas!")
		return false

	is_jumping = true

	target_position += Vector2(0, -tile_size)
	is_moving = true

	return true


func move_down():

	if is_moving:
		return false

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	if floor_check.is_colliding():
		is_moving = false
		return false

	target_position += Vector2(0, tile_size)
	is_moving = true

	return true


func should_fall():

	floor_check.target_position = Vector2(0, tile_size)
	floor_check.force_raycast_update()

	return !floor_check.is_colliding()


@onready var wall_check = $WallCheck

@onready var sprite = $AnimatedSprite2D

@onready var floor_check = $FloorCheck
