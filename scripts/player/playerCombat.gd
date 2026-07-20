extends Node
class_name PlayerCombat

@onready var sprite = $"../Visual/Knight"
@onready var state = $"../PlayerState"
@onready var sword_hitbox = $"../SwordHitbox"

var sword_offset_right = Vector2.ZERO
var sword_offset_left = Vector2(-75, 0)

var combo_step := 0
var hit_targets := []

func _ready():
	sword_hitbox.body_entered.connect(_on_sword_hitbox_body_entered)

func attack(direction := "front"):

	if state.is_busy():
		return false

	sprite.flip_h = direction == "left"

	update_sword_hitbox()

	await play_attack_combo()

	state.change_state(PlayerState.State.IDLE)

	return true

func play_attack_combo():

	match combo_step:

		0:
			combo_step = 1
			await attack_one()

		1:
			combo_step = 0
			await attack_two()

func attack_one():

	state.play_attack(1)

	AudioManager.play_sfx("attack")

	await do_hitbox(0.08,0.06)

	await sprite.animation_finished

func attack_two():

	state.play_attack(2)

	AudioManager.play_sfx("attack")

	await do_hitbox(0.08,0.15)

	await sprite.animation_finished

func do_hitbox(delay_before, active_time):

	await get_tree().create_timer(delay_before).timeout

	hit_targets.clear()

	sword_hitbox.monitoring = true

	await get_tree().create_timer(active_time).timeout

	sword_hitbox.monitoring = false

func _on_sword_hitbox_body_entered(body):

	if body in hit_targets:
		return

	hit_targets.append(body)

	var attack_dir = 1

	if sprite.flip_h:
		attack_dir = -1

	if body.has_method("take_damage"):
		await body.take_damage(1, attack_dir)

func update_sword_hitbox():

	if sprite.flip_h:
		sword_hitbox.position = sword_offset_left
	else:
		sword_hitbox.position = sword_offset_right
