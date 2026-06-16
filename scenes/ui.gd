extends CanvasLayer

@onready var code_input = $CodeInput
@onready var queue_display = $QueueDisplay
@onready var error_label = $ErrorLabel
@onready var pause_menu = $Control
@onready var commands_popup = $CommandsPopup

@onready var level_complete_popup = $LevelCompletePopup

@onready var objective_label = \
	$ObjectivePanel/ObjectiveLabel

signal run_pressed
signal restart_pressed

func _ready():
	hide_pause()
	
	commands_popup.hide()

	$MarginContainer/HBoxContainer/CommandsButton.pressed.connect(
		_on_commands_pressed
	)

	$CommandsPopup/Panel/CloseButton.pressed.connect(
		_on_close_commands_pressed
	)

	$CommandsPopup/Panel/RichTextLabel.text = """
=== MOVEMENT ===

move_right(3)
move_left(3)

=== JUMP ===

jump()
jump_right()
jump_left()

=== LOOP ===

repeat(3):
    move_right()

=== CONDITION ===

if wall_right():
    jump_right()

=== FUNCTION ===

func go():
    move_right()

go()
"""
	

func update_objectives(
	coin_done: bool,
	portal_done: bool
):

	var text = "OBJECTIVE\n\n"

	if coin_done:
		text += "[s][color=gray]Collect Coin[/color][/s]\n"
	else:
		text += "Collect Coin\n"

	if portal_done:
		text += "[s][color=gray]Reach Portal[/color][/s]"
	else:
		text += "Reach Portal"

	objective_label.text = text

func _on_commands_pressed():
	
	$CommandsPopup/Panel.pivot_offset = $CommandsPopup/Panel.size / 2
	
	commands_popup.show()
	
	$CommandsPopup/Panel.scale = Vector2.ZERO
	var pop_tween = create_tween()
	pop_tween.tween_property(
		$CommandsPopup/Panel, 
		"scale", 
		Vector2.ONE, 
		0.2
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_close_commands_pressed():

	commands_popup.hide()

func _input(event):

	if event.is_action_pressed("ui_help"):

		commands_popup.visible = \
			!commands_popup.visible

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
