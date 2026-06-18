extends Control

@onready var continue_button = $MainMenuPanel/MarginContainer/VBoxContainer/ContinueButton
@onready var parallax = $ParallaxBackground
@onready var main_buttons = $MainMenuPanel
@onready var level_select_panel = $LevelSelectPanel

@onready var banner = $LevelSelectPanel/BannerSprite
@onready var level_grid = $LevelSelectPanel/Content/GridContainer

var target_pos : Vector2
var idle_time := 0.0
var banner_start_pos : Vector2

func _process(delta):

	parallax.scroll_offset.x -= 50 * delta

	idle_time += delta

	if level_select_panel.visible:

		banner.rotation = deg_to_rad(sin(idle_time * 1.2) * 0.8)

		banner.position.y = banner_start_pos.y + sin(idle_time * 2.0) * 2

		banner.position.y = banner_start_pos.y + sin(idle_time * 2.0) * 2

func _ready():
	
	AudioManager.play_bgm("main_menu")

	banner_start_pos = banner.position

	target_pos = level_select_panel.position

	var has_save = FileAccess.file_exists(
		LevelManager.SAVE_PATH
	)

	continue_button.visible = has_save

	level_select_panel.hide()

	setup_level_buttons()
	
	if LevelManager.open_level_select:

		LevelManager.open_level_select = false

		show_level_select()

func show_level_select():

	level_select_panel.show()

	level_select_panel.scale = Vector2(0.7, 0.7)
	level_select_panel.modulate.a = 0
	level_select_panel.position.y = -500

	var tween = create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		level_select_panel,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		level_select_panel,
		"modulate:a",
		1.0,
		0.3
	)

	tween.tween_property(
		level_select_panel,
		"position",
		target_pos,
		0.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	main_buttons.hide()

	await tween.finished

	idle_time = 0

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

	#LevelManager.reset_progress()
	LevelManager.load_level(1)


func _on_level_button_pressed():

	show_level_select()


func _on_exit_button_pressed():
	get_tree().quit()


func _on_back_button_pressed():

	hide_level_select()
