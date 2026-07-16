extends CanvasLayer

@onready var code_input = $BottomLeftLayout/CodeInput
@onready var queue_display = $QueueDisplay
@onready var error_label = $ErrorLabel
@onready var pause_menu = $Pause
@onready var commands_popup = $CommandsPopup

@onready var level_complete_popup = $LevelCompletePopup

@onready var objective_label = \
	$ObjectivePanel/ObjectiveLabel
	
@onready var byte_portrait = $TutorialPopup/Control/Portrait
@onready var tutorial_popup = $TutorialPopup
@onready var tutorial_name = $TutorialPopup/Control/Name_box/Name
@onready var tutorial_message = $TutorialPopup/Control/Dialogue_box/MassageBox/MarginContainer/MessageLabel
@onready var tutorial_next = $TutorialPopup/Control/Dialogue_box/NextButton

enum ByteMood {
	IDLE
}

var tutorial_messages = []
var tutorial_index = 0

var full_text = ""
var is_typing = false
var skip_typing = false
var pulse_tween = null

signal run_pressed
signal restart_pressed

func _ready():
	hide_pause()
	
	commands_popup.hide()

	if has_node("MarginContainer/HBoxContainer/CommandsButton"):
		$HBoxContainer/CommandsButton.pressed.connect(
			_on_commands_pressed
		)

	$CommandsPopup/Panel/CloseButton.pressed.connect(
		_on_close_commands_pressed
	)

	# ==========================================
	#   KONEKSI DETEKSI KLIK OVERLAY (BARU)
	# ==========================================
	if has_node("Pause/DarkOverlay"):
		$Pause/DarkOverlay.gui_input.connect(_on_pause_overlay_gui_input)
		
	if has_node("CommandsPopup/DarkOverlay"):
		$CommandsPopup/DarkOverlay.gui_input.connect(_on_commands_overlay_gui_input)

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

	tutorial_popup.hide()

	tutorial_next.pressed.connect(
		_on_next_button_pressed
	)
	
	tutorial_next.mouse_entered.connect(_on_next_hover)
	tutorial_next.mouse_exited.connect(_on_next_exit)

func set_byte_mood(mood):
	match mood:
		ByteMood.IDLE:
			byte_portrait.play("idle")

func _on_next_hover():
	if pulse_tween:
		pulse_tween.kill()
	tutorial_next.scale = Vector2.ONE

func _on_next_exit():
	if !is_typing:
		start_next_pulse()

func update_objectives(coins_collected: int, total_coins: int, portal_done: bool):
	var text = "OBJECTIVE\n\n"
	text += "Coin: " + str(coins_collected) + "/" + str(total_coins) + "\n"
	
	if portal_done:
		text += "[s][color=gray]Reach Portal[/color][/s]"
	else:
		text += "Reach Portal"
		
	objective_label.text = text

func _on_commands_pressed():
	$CommandsPopup/Panel.pivot_offset = $CommandsPopup/Panel.size / 2
	
	AudioManager.play_ui("ui_open")
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
	AudioManager.play_ui("ui_close")
	commands_popup.hide()

func _input(event):
	if tutorial_popup.visible and event is InputEventMouseButton:
		if event.pressed:
			if is_typing:
				skip_typing = true

	if tutorial_popup.visible:
		if event.is_action_pressed("ui_accept"):
			if is_typing:
				skip_typing = true
			else:
				_on_next_button_pressed()
			get_viewport().set_input_as_handled()
			return

	# ==========================================
	#     SISTEM KEYBOARD SHORTCUTS
	# ==========================================

	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		_on_menu_button_pressed()
		get_viewport().set_input_as_handled()
		return

	if pause_menu.visible:
		return

	if event.is_action_pressed("ui_help") or (event is InputEventKey and event.pressed and event.keycode == KEY_F1) or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		if commands_popup.visible:
			_on_close_commands_pressed()
		else:
			_on_commands_pressed()
		get_viewport().set_input_as_handled()

	elif (event is InputEventKey and event.pressed and event.keycode == KEY_F6) or (event is InputEventKey and event.pressed and event.keycode == KEY_R and event.ctrl_pressed):
		_on_restart_button_pressed()
		get_viewport().set_input_as_handled()

	elif (event is InputEventKey and event.pressed and event.keycode == KEY_F5) or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and event.ctrl_pressed):
		_on_run_button_pressed()
		get_viewport().set_input_as_handled()

func show_level_complete(level_number: int, coins_collected: int, total_coins: int):
	level_complete_popup.set_coin_text(coins_collected, total_coins)
	level_complete_popup.show_popup(level_number)

func _on_run_button_pressed():
	AudioManager.play_run()
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

func start_tutorial(messages):
	tutorial_messages = messages
	tutorial_index = 0
	show_current_tutorial()
	
func show_current_tutorial():
	tutorial_popup.show()
	var data = tutorial_messages[tutorial_index]
	full_text = data["text"]
	match data["mood"]:
		"idle":
			set_byte_mood(ByteMood.IDLE)
	tutorial_message.visible_characters = 0
	start_typewriter()

func start_typewriter():
	is_typing = true
	skip_typing = false
	tutorial_next.hide()
	tutorial_message.bbcode_enabled = true
	tutorial_message.text = full_text
	tutorial_message.visible_characters = 0
	AudioManager.play_speak()
	var total = tutorial_message.get_total_character_count()
	for i in range(total + 1):
		if skip_typing:
			tutorial_message.visible_characters = total
			break
		tutorial_message.visible_characters = i
		await get_tree().create_timer(0.03).timeout
	is_typing = false
	AudioManager.stop_speak()
	tutorial_next.show()
	start_next_pulse()

func _on_next_button_pressed():
	tutorial_index += 1
	if tutorial_index >= tutorial_messages.size():
		tutorial_popup.hide()
		return
	show_current_tutorial()

func start_next_pulse():
	if pulse_tween:
		pulse_tween.kill()
	tutorial_next.scale = Vector2.ONE
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(
		tutorial_next,
		"scale",
		Vector2(1.08, 1.08),
		0.5
	)
	pulse_tween.tween_property(
		tutorial_next,
		"scale",
		Vector2.ONE,
		0.5
	)

# ==========================================
#     FUNGSI DETEKSI KLIK OVERLAY (BARU)
# ==========================================

func _on_pause_overlay_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			hide_pause()

func _on_commands_overlay_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_close_commands_pressed()
