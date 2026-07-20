extends Control

@onready var parallax = $ParallaxBackground
@onready var main_buttons = $MainMenuPanel
@onready var level_select_panel = $LevelSelectPanel
@onready var level_grid = $LevelSelectPanel/Content/GridContainer
@onready var level_select_overlay = $LevelSelectPanel/ColorRect

var target_pos : Vector2
var idle_time := 0.0
var banner_start_pos : Vector2

func _process(delta):
	parallax.scroll_offset.x -= 50 * delta
	idle_time += delta

func _ready():
	AudioManager.play_bgm("main_menu")

	target_pos = level_select_panel.position

	var has_save = FileAccess.file_exists(
		LevelManager.SAVE_PATH
	)

	level_select_panel.hide()
	LevelManager.load_progress()
	setup_level_buttons()
	
	if LevelManager.open_level_select:
		LevelManager.open_level_select = false
		show_level_select()

	if level_select_overlay:
		level_select_overlay.gui_input.connect(_on_overlay_gui_input)

func show_level_select():
	level_select_panel.show()

	level_select_panel.position = target_pos
	level_select_panel.scale = Vector2(0.85, 0.85)
	level_select_panel.modulate.a = 0.0

	level_select_panel.pivot_offset = level_select_panel.size / 2

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		level_select_panel,
		"scale",
		Vector2.ONE,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		level_select_panel,
		"modulate:a",
		1.0,
		0.25
	)

	main_buttons.hide()
	await tween.finished
	idle_time = 0

func hide_level_select():
	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		level_select_panel,
		"scale",
		Vector2(0.9, 0.9),
		0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.tween_property(
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
		var button = level_grid.get_node("LevelButton" + str(i))
		var button_label = button.get_node("Label")
		var color_rect = button.get_node_or_null("ColorRect")

		if i <= LevelManager.unlocked_level:
			button.disabled = false
			if button_label:
				button_label.text = str(i)

			if not button.pressed.is_connected(_on_level_pressed):
				button.pressed.connect(_on_level_pressed.bind(i, button))

			if color_rect and color_rect.material is ShaderMaterial:
				color_rect.material = color_rect.material.duplicate()
				
				color_rect.material.set_shader_parameter("hover_intensity", 0.0)

				button.mouse_entered.connect(func():
					var tween = create_tween()
					tween.tween_property(color_rect.material, "shader_parameter/hover_intensity", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
				)

				button.mouse_exited.connect(func():
					var tween = create_tween()
					tween.tween_property(color_rect.material, "shader_parameter/hover_intensity", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
				)
		else:
			button.disabled = true
			if button_label:
				button_label.text = "X"

			if color_rect and color_rect.material is ShaderMaterial:
				color_rect.material = color_rect.material.duplicate()
				color_rect.material.set_shader_parameter("hover_intensity", 0.0)

func _on_level_pressed(level_number, button: TextureButton):
	var button_label = button.get_node_or_null("Label")
	
	if button_label:
		var glow_tween = create_tween()
		button_label.modulate = Color(5, 5, 5, 1)
		glow_tween.tween_property(button_label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_SINE)
	
	await get_tree().create_timer(0.15).timeout
	LevelManager.load_level(level_number)

func _on_exit_button_pressed():
	get_tree().quit()

func _on_start_button_pressed():
	show_level_select()

func _on_back_button_pressed():
	hide_level_select()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_overlay_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			hide_level_select()
