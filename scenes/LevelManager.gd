extends Node

var current_level = 1
var unlocked_level = 1

const SAVE_PATH = "user://save.dat"


func _ready():

	load_progress()

func load_level(level):

	current_level = level

	get_tree().change_scene_to_file(
		"res://scenes/levels/Level%d.tscn" % level
	)


func next_level():

	load_level(current_level + 1)


# ======================
# SAVE
# ======================

func save_progress():

	var save_file = FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if save_file == null:

		print("FAILED TO CREATE SAVE FILE")
		return

	save_file.store_var(unlocked_level)

	print("Progress saved:", unlocked_level)
	print("Location:", ProjectSettings.globalize_path(SAVE_PATH))


func load_progress():

	if !FileAccess.file_exists(SAVE_PATH):

		print("No save found")

		return

	var save_file = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	unlocked_level = save_file.get_var()

# ======================
# testing
# ======================

func reset_progress():

	unlocked_level = 1

	save_progress()

	print("Progress reset")
