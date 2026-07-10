extends CharacterBody2D
class_name Enemy

@export var max_health := 2
@export var move_speed := 0.25
@export var aggro_range := 5
@export var attack_range := 1
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea
@export var max_move_per_turn := 1

enum State {
	IDLE,
	HIT,
	DEAD
}

enum AIState {
	PATROL,
	NOTICE,
	CHASE,
	ATTACK
}

var player_detected := false
var noticed := false
var player_in_attack := false
var target_player = null
var tile_size = 32
var health := 0
var current_state = State.IDLE
var queued_hits := 0
var last_attack_dir := 1

static var combat_count := 0

var turn_delay := false
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

	if player_in_attack:
		ai_state = AIState.ATTACK
		await attack_player(player)
		return

	if player_detected:

		if noticed:
			ai_state = AIState.NOTICE
			await notice_player(player)
			return

		ai_state = AIState.CHASE
		await chase_player(player.global_position.x - global_position.x)
		return

	ai_state = AIState.PATROL
	await patrol()

func patrol():

	if obstacle_ahead(move_dir):
		move_dir *= -1
		return

	await move_direction(move_dir)

func notice_player(player):

	anim.flip_h = player.global_position.x < global_position.x

	anim.play("idle")

	AudioManager.play_sfx("enemy_notice")

	await get_tree().create_timer(0.35).timeout

	noticed = false

func chase_player(_distance):

	for i in range(get_move_count()):

		if target_player == null:
			break

		var dir = sign(target_player.global_position.x - global_position.x)

		if dir == 0:
			break

		move_dir = dir

		var dist = abs(target_player.global_position.x - global_position.x)

		if dist <= attack_range * tile_size:
			break

		var next_dist = abs(
			target_player.global_position.x
			- (global_position.x + dir * tile_size)
		)

		if next_dist < attack_range * tile_size:
			break

		if obstacle_ahead(dir):
			break

		await move_direction(dir)

func get_move_count():
	return max_move_per_turn

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
	await get_tree().create_timer(0.3).timeout

	AudioManager.play_sfx("enemy_attack")
	await anim.animation_finished

	await player.die()

func obstacle_ahead(dir):

	wall_check.target_position = Vector2(tile_size * dir,0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():

		var body = wall_check.get_collider()

		if body is Enemy:
			return ai_state == AIState.PATROL

		if body.name == "Player":
			return false

		return true

	floor_check.target_position = Vector2(tile_size * dir,tile_size)
	floor_check.force_raycast_update()

	if !floor_check.is_colliding():
		return true

	var floor = floor_check.get_collider()

	if floor.is_in_group("spike"):
		return true

	return false

func enemy_ahead(dir):

	wall_check.target_position = Vector2(tile_size * dir,0)
	wall_check.force_raycast_update()

	if wall_check.is_colliding():

		var body = wall_check.get_collider()

		if body is Enemy:

			body.move_dir *= -1
			move_dir *= -1

			return true

	return false

func enter_combat():

	combat_count += 1

	if combat_count == 1:
		AudioManager.fade_to_bgm("combat")

func leave_combat():

	combat_count -= 1

	if combat_count <= 0:
		combat_count = 0
		AudioManager.fade_to_bgm("gameplay")

func _on_detection_area_body_entered(body):
	if body.name == "Player":

		player_detected = true
		target_player = body

		if !noticed:
			noticed = true

		enter_combat()

func _on_detection_area_body_exited(body):
	if body == target_player:

		player_detected = false
		target_player = null

		noticed = false

		leave_combat()


func _on_attack_area_body_entered(body):
	if body.name == "Player":
		player_in_attack = true

func _on_attack_area_body_exited(body):
	if body.name == "Player":
		player_in_attack = false
