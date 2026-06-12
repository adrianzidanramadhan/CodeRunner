extends CanvasLayer

@onready var code_input = $CodeInput
@onready var queue_display = $QueueDisplay
@onready var error_label = $ErrorLabel
@onready var pause_menu = $Control

@onready var level_complete_popup = $LevelCompletePopup

signal run_pressed
signal restart_pressed

func _ready():
	hide_pause()

func show_level_complete(level_number):

	level_complete_popup.show_popup(
		level_number
	)

func _on_run_button_pressed():
	run_pressed.emit()

func _on_restart_button_pressed():
	restart_pressed.emit()

func update_queue_display(command_queue, current_index = -1):

	queue_display.text = ""

	for i in range(command_queue.size()):

		var command = command_queue[i]

		var text = str(command)

		if i == current_index:

			queue_display.text += (
				"[color=yellow]▶ "
				+ text
				+ "[/color]\n"
			)

		else:

			queue_display.text += text + "\n"


func show_error(message, line = -1):

	if line >= 0:

		error_label.text = (
			"Line "
			+ str(line + 1)
			+ ": "
			+ message
		)

	else:

		error_label.text = message


func clear_error():

	error_label.text = ""


func highlight_line(line):

	if line >= 0:

		code_input.set_caret_line(line)

		code_input.center_viewport_to_caret()

func show_pause():

	pause_menu.visible = true
	get_tree().paused = true


func hide_pause():

	pause_menu.visible = false
	get_tree().paused = false

func _on_exit_to_menu_button_pressed():

	get_tree().paused = false

	get_tree().change_scene_to_file(
		"res://scenes/MainMenu.tscn"
	)

func _on_resume_button_pressed():

	hide_pause()

func _on_menu_button_pressed():

	if pause_menu.visible:

		hide_pause()

	else:

		show_pause()
