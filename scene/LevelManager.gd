# LevelManager.gd

extends Node

var current_level = 1

func load_level(level_number):

	current_level = level_number

	var path = "res://scenes/levels/level_%d.tscn" % level_number

	get_tree().change_scene_to_file(path)
