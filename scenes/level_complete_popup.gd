extends Control

@onready var banner = $Banner

var banner_start_pos : Vector2
var idle_time := 0.0

var next_level = 1

func _process(delta):

	if visible:

		idle_time += delta

		banner.rotation_degrees = sin(idle_time * 1.5) * 1.0

		banner.position.y = (
			banner_start_pos.y
			+ sin(idle_time * 2.0) * 2
		)

func _ready():

	visible = false

	banner_start_pos = banner.position


func show_popup(level_number):

	next_level = min(
		level_number + 1,
		LevelManager.MAX_LEVEL
	)

	visible = true

	idle_time = 0

	banner.scale = Vector2(0.7, 0.7)
	banner.modulate.a = 0

	banner.position = banner_start_pos + Vector2(0, -300)

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		banner,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		banner,
		"modulate:a",
		1.0,
		0.3
	)

	tween.tween_property(
		banner,
		"position",
		banner_start_pos,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		banner,
		"rotation_degrees",
		0,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_next_button_pressed():
	#LevelManager.load_level(next_level)
	LevelManager.next_level()

func _on_level_select_button_pressed():

	LevelManager.open_level_select = true

	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)
