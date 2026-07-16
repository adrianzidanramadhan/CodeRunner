extends Control

const HEART_SCENE = preload("res://scenes/Heart.tscn")

@onready var container = $HBoxContainer

var hearts = []

func _ready():

	HealthManager.hp_changed.connect(update_hearts)

	create_hearts()

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

	for i in range(max_hp):

		if i < current_hp:
			hearts[i].set_full()
		else:
			hearts[i].set_empty()
