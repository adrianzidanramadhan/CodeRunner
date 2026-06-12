extends Control

@onready var continue_button = $MainMenuPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var parallax = $ParallaxBackground
@onready var main_buttons = $MainMenuPanel
@onready var level_select_panel = $LevelSelectPanel

@onready var level_grid = $LevelSelectPanel/MarginContainer/Banner/GridContainer

var target_pos : Vector2

func _process(delta):
	parallax.scroll_offset.x -= 50 * delta

func _ready():

	target_pos = level_select_panel.position

	var has_save = FileAccess.file_exists(
		LevelManager.SAVE_PATH
	)

	continue_button.visible = has_save

	level_select_panel.hide()

	setup_level_buttons()

func show_level_select():

	level_select_panel.show()

	level_select_panel.scale = Vector2(0.8, 0.8)
	level_select_panel.modulate.a = 0
	level_select_panel.position.y = -500

	var tween = create_tween()

	tween.parallel().tween_property(
		level_select_panel,
		"scale",
		Vector2.ONE,
		0.25
	)

	tween.parallel().tween_property(
		level_select_panel,
		"modulate:a",
		1.0,
		0.25
	)
	
	tween.tween_property(
		level_select_panel,
		"position",
		target_pos,
		0.3
	)

	main_buttons.hide()

func hide_level_select():

	var tween = create_tween()

	tween.parallel().tween_property(
		level_select_panel,
		"scale",
		Vector2(0.8, 0.8),
		0.2
	)

	tween.parallel().tween_property(
		level_select_panel,
		"modulate:a",
		0.0,
		0.2
	)

	await tween.finished

	level_select_panel.hide()

	main_buttons.show()

func setup_level_buttons():

	for i in range(1, 13):

		var button = level_grid.get_node(
			"LevelButton" + str(i)
		)

		if i <= LevelManager.unlocked_level:

			button.disabled = false
			button.text = str(i)

			button.pressed.connect(
				_on_level_pressed.bind(i)
			)

		else:

			button.disabled = true
			button.text = "🔒"

func _on_level_pressed(level_number):

	LevelManager.load_level(level_number)
	



func _on_continue_button_pressed():

	LevelManager.continue_game()


func _on_play_button_pressed():

	LevelManager.reset_progress()
	LevelManager.load_level(1)


func _on_level_button_pressed():

	show_level_select()


func _on_exit_button_pressed():
	get_tree().quit()


func _on_back_button_pressed():

	hide_level_select()
