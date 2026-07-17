extends Control

const HEART_SCENE = preload("res://scenes/Heart.tscn")

@onready var damage_flash = $"../DamageFlash"
@onready var container = $HBoxContainer
@onready var emblem = $"Emblem"

var container_start := Vector2.ZERO
var hearts = []
var previous_hp := 0
var start_position : Vector2


var is_full := true
var is_playing := false

func _ready():
	container_start = container.position
	start_position = position

	HealthManager.hp_changed.connect(update_hearts)

	create_hearts()

	previous_hp = HealthManager.current_hp

	start_shine()


func create_hearts():

	for child in container.get_children():
		child.queue_free()

	hearts.clear()

	for i in range(HealthManager.max_hp):

		var heart = HEART_SCENE.instantiate()

		container.add_child(heart)

		hearts.append(heart)

	update_hearts(
		HealthManager.current_hp,
		HealthManager.max_hp
	)


func update_hearts(current_hp, max_hp):

	# DAMAGE
	if current_hp < previous_hp:

		play_damage_flash()

		for i in range(current_hp, previous_hp):

			if i < hearts.size():
				hearts[i].play_damage()

		await get_tree().create_timer(0.03).timeout

		shake()

	# HEAL
	elif current_hp > previous_hp:

		for i in range(previous_hp, current_hp):

			if i < hearts.size():

				hearts[i].play_heal()

	# Sinkronisasi (kalau load game / reset)
	for i in range(max_hp):

		if i >= hearts.size():
			continue

		if i < current_hp:

			if !hearts[i].is_full:
				hearts[i].set_full()

		else:

			if hearts[i].is_full:
				hearts[i].set_empty()

	previous_hp = current_hp


func start_shine():

	shine_loop()


func shine_loop():

	while true:

		await get_tree().create_timer(randf_range(3,6)).timeout

		await emblem.shine()

		await get_tree().create_timer(0.1).timeout

		for heart in hearts:

			if heart.is_full:

				heart.play_shine()

				await get_tree().create_timer(0.08).timeout

		bounce_bar()


func bounce_bar():

	var tween = create_tween()

	tween.tween_property(
		container,
		"scale",
		Vector2(1.03,1.03),
		0.08
	)

	tween.tween_property(
		container,
		"scale",
		Vector2.ONE,
		0.12
	)


func play_damage_flash():

	damage_flash.color = Color.WHITE
	damage_flash.modulate.a = 0.9

	var tween = create_tween()

	tween.tween_property(
		damage_flash,
		"modulate:a",
		0.35,
		0.05
	)

	damage_flash.color = Color(1,0.2,0.2)

	tween.tween_property(
		damage_flash,
		"modulate:a",
		0,
		0.10
	)

func shake():

	var tween = create_tween()

	tween.tween_property(
		container,
		"position:x",
		container_start.x - 5,
		0.02
	)

	tween.tween_property(
		container,
		"position:x",
		container_start.x + 5,
		0.02
	)

	tween.tween_property(
		container,
		"position:x",
		container_start.x - 3,
		0.02
	)

	tween.tween_property(
		container,
		"position:x",
		container_start.x,
		0.03
	)
