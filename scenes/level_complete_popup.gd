extends Control

var next_level = 1

func _ready():
	visible = false

func show_popup(level_number):
	next_level = level_number + 1
	visible = true

	scale = Vector2(0.8, 0.8)
	modulate.a = 0

	var tween = create_tween()

	tween.parallel().tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.25
	)

	tween.parallel().tween_property(
		self,
		"modulate:a",
		1.0,
		0.25
	)

func _on_next_button_pressed():

	get_tree().change_scene_to_file(
		"res://scenes/levels/Level%d.tscn" % next_level
	)

func _on_level_select_button_pressed():

	LevelManager.open_level_select = true

	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)
