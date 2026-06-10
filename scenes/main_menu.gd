extends Control

@onready var continue_button = $VBoxContainer/ContinueButton

func _ready():

	var has_save = FileAccess.file_exists(
		LevelManager.SAVE_PATH
	)

	continue_button.visible = has_save

func _on_continue_button_pressed():

	LevelManager.continue_game()

func _on_play_button_pressed():

	LevelManager.reset_progress()
	LevelManager.load_level(1)


func _on_level_button_pressed():
	get_tree().change_scene_to_file(
		"res://scenes/LevelSelect.tscn"
	)


func _on_exit_button_pressed():
	get_tree().quit()
