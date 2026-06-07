extends Control

var next_level = 1

func _ready():
	visible = false

func show_popup(level_number):
	next_level = level_number + 1
	visible = true
	
	modulate.a = 0 
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _on_next_button_pressed():

	get_tree().change_scene_to_file(
		"res://scenes/levels/Level%d.tscn" % next_level
	)

func _on_level_select_button_pressed():
	
	get_tree().change_scene_to_file(
		"res://scenes/LevelSelect.tscn"
	)
