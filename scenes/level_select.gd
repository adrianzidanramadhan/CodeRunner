extends Control

func _ready():
	print("LEVEL SELECT LOADED")
	
	for i in range(1, 13):
		var button = $GridContainer.get_node_or_null("LevelButton" + str(i))
		
		if button:
			setup_button(button, i)
			button.pressed.connect(_on_level_pressed.bind(i))

func setup_button(button, level_number):
	if level_number <= LevelManager.unlocked_level:
		button.disabled = false
		button.text = str(level_number)
	else:
		button.disabled = true
		button.text = "🔒"

func _on_level_pressed(level_number):
	var scene_path = "res://scenes/levels/Level" + str(level_number) + ".tscn"
	get_tree().change_scene_to_file(scene_path)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
