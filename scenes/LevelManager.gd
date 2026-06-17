extends Node

const MAX_LEVEL = 12

var current_level = 1
var unlocked_level = 1
var open_level_select = false

const SAVE_PATH = "user://save.dat"


func get_level_path(level):

	return "res://scenes/levels/Level%d.tscn" % level


func _ready():

	load_progress()

func load_level(level):

	current_level = level
	
	save_progress()

	call_deferred("_deferred_load_level", level)

func _deferred_load_level(level):
	get_tree().change_scene_to_file(
		get_level_path(level)
	)

func continue_game():

	load_level(current_level)

func next_level():

	if current_level < MAX_LEVEL:

		load_level(current_level + 1)

	else:

		print("All levels completed")


func reload_level():

	load_level(current_level)


func unlock_level(level):

	level = min(level, MAX_LEVEL)
	
	if level > unlocked_level:

		unlocked_level = level

		save_progress()

		print("Unlocked Level ", level)

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

	var save_data = {

		"current_level": current_level,
		"unlocked_level": unlocked_level

	}

	save_file.store_var(save_data)

	print(
		"Progress saved:",
		current_level,
		unlocked_level
	)


func load_progress():

	if !FileAccess.file_exists(SAVE_PATH):
		print("No save found")
		return

	var save_file = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	var save_data = save_file.get_var()

	# SAVE LAMA
	if save_data is int:

		unlocked_level = save_data
		current_level = 1

		print("Old save loaded")

	# SAVE BARU
	elif save_data is Dictionary:

		current_level = save_data.get(
			"current_level",
			1
		)

		unlocked_level = save_data.get(
			"unlocked_level",
			1
		)

	print(
		"Loaded:",
		current_level,
		unlocked_level
	)

# ======================
# testing
# ======================

func reset_progress():

	unlocked_level = 1

	save_progress()

	print("Progress reset")
