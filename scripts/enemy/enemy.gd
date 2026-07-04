extends CharacterBody2D
class_name Enemy

@export var max_health := 2
@export var move_speed := 0.25
@export var aggro_range := 5
@export var attack_range := 1

enum State {
	IDLE,
	HIT,
	DEAD
}

enum AIState {
	PATROL,
	CHASE,
	ATTACK
}

var tile_size = 32
var health := 0
var current_state = State.IDLE
var queued_hits := 0
var last_attack_dir := 1

var ai_state = AIState.PATROL
var move_dir = 1

@export var anim_path: NodePath
@onready var anim = get_node(anim_path)
@onready var wall_check = $WallCheck
@onready var floor_check = $FloorCheck


func _ready():
	health = max_health
	anim.play("idle")


func take_damage(amount := 1, attack_dir := 1):
	if current_state == State.DEAD:
		return

	last_attack_dir = attack_dir
	health -= amount

	print("Enemy HP:", health)

	# Jika sedang animasi hit → simpan hit berikutnya
	if current_state == State.HIT:
		queued_hits += 1
		return

	await play_hit(attack_dir)


func play_hit(direction := 1):
	current_state = State.HIT

	# flip sesuai arah serangan
	anim.flip_h = direction > 0

	# flash putih
	modulate = Color(1.4, 1.4, 1.4)

	# knockback kecil
	var original_pos = position
	var tween = create_tween()

	tween.tween_property(
		self,
		"position",
		original_pos + Vector2(8 * direction, 0),
		0.05
	)

	tween.tween_property(
		self,
		"position",
		original_pos,
		0.08
	)

	# restart animasi hit dari frame awal
	anim.stop()
	anim.frame = 0
	anim.play("take_hit")

	await get_tree().create_timer(0.05).timeout
	modulate = Color.WHITE

	await anim.animation_finished

	# Jika ada hit berikutnya
	if queued_hits > 0:
		queued_hits -= 1
		await play_hit(last_attack_dir)
		return

	# Jika HP habis
	if health <= 0:
		await get_tree().create_timer(0.15).timeout
		await die()
		return

	current_state = State.IDLE
	anim.play("idle")


func die():
	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	velocity = Vector2.ZERO

	AudioManager.play_sfx("enemy_death")

	anim.stop()
	anim.frame = 0
	anim.play("death")

	await anim.animation_finished
	queue_free()

func take_turn(player):
	if current_state == State.DEAD:
		return

	var distance = player.global_position.x - global_position.x

	if abs(distance) <= attack_range * tile_size:
		ai_state = AIState.ATTACK
	elif abs(distance) <= aggro_range * tile_size:
		ai_state = AIState.CHASE
	else:
		ai_state = AIState.PATROL

	match ai_state:
		AIState.PATROL:
			await patrol()
		AIState.CHASE:
			await chase_player(distance)
		AIState.ATTACK:
			await attack_player(player)

func patrol():
	if obstacle_ahead(move_dir):
		move_dir *= -1

	await move_direction(move_dir)

func chase_player(distance):
	var dir = 1 if distance > 0 else -1

	if obstacle_ahead(dir):
		return

	move_dir = dir
	await move_direction(dir)

func move_direction(dir):
	var target = position
	target.x += tile_size * dir

	anim.flip_h = dir < 0
	anim.play("run")

	var tween = create_tween()
	tween.tween_property(self, "position", target, move_speed)

	await tween.finished

	anim.play("idle")

func attack_player(player):
	
	anim.play("attack")
	get_tree().create_timer(0.3).timeout.connect(func(): 
		AudioManager.play_sfx("enemy_attack")
	)
	await anim.animation_finished

	await player.die()

func obstacle_ahead(dir):
	wall_check.target_position = Vector2(tile_size * dir, 0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():
		return true

	floor_check.target_position = Vector2(tile_size * dir, tile_size)
	floor_check.force_raycast_update()

	if !floor_check.is_colliding():
		return true

	if floor_check.is_colliding():
		var body = floor_check.get_collider()
		if body.is_in_group("spike"):
			return true

	var collider = wall_check.get_collider()
	if collider is Enemy:
		return true
