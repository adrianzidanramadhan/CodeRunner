extends Control

const MAIN_MENU = "res://scenes/MainMenu.tscn"

@onready var logo = $Logo

var skipped := false

func _ready():

	logo.scale = Vector2(0.7, 0.7)
	logo.modulate.a = 0

	AudioManager.play_sfx("logo")

	var tween = create_tween()

	# Fade in + zoom
	tween.parallel().tween_property(
		logo,
		"modulate:a",
		1.0,
		1.0
	)

	tween.parallel().tween_property(
		logo,
		"scale",
		Vector2.ONE,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Diam sebentar
	tween.tween_interval(2.0)

	# Fade out + zoom sedikit
	tween.parallel().tween_property(
		logo,
		"modulate:a",
		0.0,
		1.0
	)

	tween.parallel().tween_property(
		logo,
		"scale",
		Vector2(1.08, 1.08),
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

	if !skipped:
		goto_menu()

func _input(event):

	if skipped:
		return

	if event.is_pressed():
		skipped = true
		goto_menu()

func goto_menu():
	get_tree().change_scene_to_file(MAIN_MENU)
